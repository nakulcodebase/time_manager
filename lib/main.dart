import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'gemini_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TimeManagementApp());
}

class TimeManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Management Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  DateTime currentTime = DateTime.now();
  Timer? _timer;
  double dayWastePercentage = 0.0;
  List<Task> tasks = [];
  int lifetimeFailures = 0;
  AnimationController? _pulseController;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    try {
      WidgetsBinding.instance.addObserver(this);
      _startRealTimeClock();
      _loadLifetimeFailures();
      _loadTasks();
      _pulseController = AnimationController(
        vsync: this,
        duration: Duration(seconds: 2),
      )..repeat(reverse: true);
    } catch (e) {
      print('Error in initState: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    try {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
      _pulseController?.dispose();
      _saveTasks();
    } catch (e) {
      print('Error in dispose: $e');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      if (state == AppLifecycleState.paused) {
        _saveTasks();
      } else if (state == AppLifecycleState.resumed) {
        _loadTasks();
        if (!_isDisposed && mounted) {
          setState(() {
            currentTime = DateTime.now();
          });
        }
      }
    } catch (e) {
      print('Error in lifecycle: $e');
    }
  }

  void _startRealTimeClock() {
    try {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!_isDisposed && mounted) {
          try {
            setState(() {
              currentTime = DateTime.now();
              _calculateDayWastePercentage();
            });
          } catch (e) {
            print('Error updating time: $e');
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error starting clock: $e');
    }
  }

  void _calculateDayWastePercentage() {
    try {
      int currentHour = currentTime.hour;
      if (currentHour < 11) {
        dayWastePercentage = ((currentHour - 8) / 24) * 100;
        if (dayWastePercentage < 0) dayWastePercentage = 0;
      }
    } catch (e) {
      print('Error calculating percentage: $e');
    }
  }

  Future<void> _loadLifetimeFailures() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (!_isDisposed && mounted) {
        setState(() {
          lifetimeFailures = prefs.getInt('lifetime_failures') ?? 0;
        });
      }
    } catch (e) {
      print('Error loading failures: $e');
    }
  }

  Future<void> _saveLifetimeFailures() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lifetime_failures', lifetimeFailures);
    } catch (e) {
      print('Error saving failures: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tasksJson = prefs.getString('tasks');
      if (tasksJson != null && !_isDisposed && mounted) {
        List<dynamic> tasksList = json.decode(tasksJson);
        setState(() {
          tasks = tasksList.map((t) => Task.fromJson(t)).toList();
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> _saveTasks() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String tasksJson = json.encode(tasks.map((t) => t.toJson()).toList());
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    int activeTasks = tasks.where((t) => !t.isCompleted && !t.isFailed).length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Time Management Pro',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.person_outline, size: 28),
            onPressed: () {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      lifetimeFailures: lifetimeFailures,
                      totalTasks: tasks.length,
                      completedTasks: tasks.where((t) => t.isCompleted).length,
                    ),
                  ),
                );
              } catch (e) {
                print('Error navigating to profile: $e');
              }
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black54, Colors.deepPurple.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade200,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(Icons.access_time, color: Colors.white70, size: 32),
                  SizedBox(height: 8),
                  Text(
                    DateFormat('EEEE, MMMM dd, yyyy').format(currentTime),
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70),
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateFormat('hh:mm:ss a').format(currentTime),
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip(Icons.check_circle_outline, '$activeTasks Active', Colors.white24),
                      SizedBox(width: 12),
                      _buildStatChip(Icons.done_all, '${tasks.where((t) => t.isCompleted).length} Done', Colors.white24),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            if (currentTime.hour < 11 && _pulseController != null)
              AnimatedBuilder(
                animation: _pulseController!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_pulseController!.value * 0.02),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade300, Colors.deepOrange.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade200,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 32),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Day Waste Alert',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                SizedBox(height: 4),
                                Text('${dayWastePercentage.toStringAsFixed(1)}% of day wasted',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Your Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                ElevatedButton.icon(
                  icon: Icon(Icons.add_circle_outline, size: 22),
                  label: Text('New Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  onPressed: () async {
                    try {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddTaskScreen()),
                      );
                      if (result != null && !_isDisposed && mounted) {
                        setState(() {
                          tasks.add(result);
                        });
                        await _saveTasks();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ Task created successfully!'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error adding task: $e');
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 16),

            Expanded(
              child: tasks.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.deepPurple.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.task_outlined, size: 80, color: Colors.deepPurple.shade300),
                    ),
                    SizedBox(height: 24),
                    Text('No tasks yet!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                    SizedBox(height: 8),
                    Text('Tap "New Task" to get started', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(
                    task: tasks[index],
                    currentTime: currentTime,
                    onComplete: () async {
                      try {
                        if (tasks[index].taskType != 'writing') {
                          final passed = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => AICheckerScreen(task: tasks[index])),
                          );
                          if (passed == true && !_isDisposed && mounted) {
                            setState(() {
                              tasks[index].isCompleted = true;
                            });
                            await _saveTasks();
                          }
                        } else {
                          if (!_isDisposed && mounted) {
                            setState(() {
                              tasks[index].isCompleted = true;
                            });
                            await _saveTasks();
                          }
                        }
                      } catch (e) {
                        print('Error completing task: $e');
                      }
                    },
                    onFailed: () async {
                      try {
                        if (!_isDisposed && mounted) {
                          setState(() {
                            lifetimeFailures++;
                            tasks[index].isFailed = true;
                          });
                          await _saveLifetimeFailures();
                          await _saveTasks();
                        }
                      } catch (e) {
                        print('Error marking task as failed: $e');
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.shade200,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Lifetime Failures: $lifetimeFailures',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color bgColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ============================================================================
// TASK MODEL
// ============================================================================

class Task {
  String title;
  String description;
  String taskType;
  String? subject;
  String? topic;
  int targetHours;
  int targetMinutes;
  DateTime startTime;
  DateTime? pausedTime;
  int elapsedSeconds;
  bool isCompleted;
  bool isFailed;
  bool isPaused;

  Task({
    required this.title,
    required this.description,
    required this.taskType,
    this.subject,
    this.topic,
    required this.targetHours,
    required this.targetMinutes,
    required this.startTime,
    this.pausedTime,
    this.elapsedSeconds = 0,
    this.isCompleted = false,
    this.isFailed = false,
    this.isPaused = false,
  });

  int get totalTargetSeconds => (targetHours * 3600) + (targetMinutes * 60);

  int getRemainingSeconds(DateTime currentTime) {
    try {
      if (isFailed || isCompleted) return 0;
      int elapsed = elapsedSeconds;
      if (!isPaused) {
        elapsed += currentTime.difference(startTime).inSeconds;
      }
      return totalTargetSeconds - elapsed;
    } catch (e) {
      print('Error calculating remaining seconds: $e');
      return 0;
    }
  }

  Map<String, dynamic> toJson() {
    try {
      return {
        'title': title,
        'description': description,
        'taskType': taskType,
        'subject': subject,
        'topic': topic,
        'targetHours': targetHours,
        'targetMinutes': targetMinutes,
        'startTime': startTime.toIso8601String(),
        'pausedTime': pausedTime?.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'isCompleted': isCompleted,
        'isFailed': isFailed,
        'isPaused': isPaused,
      };
    } catch (e) {
      print('Error converting task to JSON: $e');
      return {};
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    try {
      return Task(
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        taskType: json['taskType'] ?? 'learning',
        subject: json['subject'],
        topic: json['topic'],
        targetHours: json['targetHours'] ?? 0,
        targetMinutes: json['targetMinutes'] ?? 30,
        startTime: DateTime.parse(json['startTime'] ?? DateTime.now().toIso8601String()),
        pausedTime: json['pausedTime'] != null ? DateTime.parse(json['pausedTime']) : null,
        elapsedSeconds: json['elapsedSeconds'] ?? 0,
        isCompleted: json['isCompleted'] ?? false,
        isFailed: json['isFailed'] ?? false,
        isPaused: json['isPaused'] ?? false,
      );
    } catch (e) {
      print('Error parsing task from JSON: $e');
      return Task(
        title: 'Error Task',
        description: 'Failed to load',
        taskType: 'learning',
        targetHours: 0,
        targetMinutes: 30,
        startTime: DateTime.now(),
      );
    }
  }
}

// ============================================================================
// ADD TASK SCREEN
// ============================================================================

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  String title = '';
  String description = '';
  String taskType = 'learning';
  String? subject;
  String? topic;
  int targetHours = 0;
  int targetMinutes = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Create New Task', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title, color: Colors.deepPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                onSaved: (value) => title = value!,
              ),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'What will you do?',
                  prefixIcon: Icon(Icons.description, color: Colors.deepPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Please describe the task' : null,
                onSaved: (value) => description = value!,
              ),
              SizedBox(height: 20),
              Text('Type of Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: taskType,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.category, color: Colors.deepPurple),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: [
                  DropdownMenuItem(value: 'learning', child: Row(children: [
                    Icon(Icons.school, color: Colors.blue), SizedBox(width: 8), Text('Learning')])),
                  DropdownMenuItem(value: 'programming', child: Row(children: [
                    Icon(Icons.code, color: Colors.green), SizedBox(width: 8), Text('Programming')])),
                  DropdownMenuItem(value: 'writing', child: Row(children: [
                    Icon(Icons.edit, color: Colors.orange), SizedBox(width: 8), Text('Writing')])),
                ],
                onChanged: (value) => setState(() => taskType = value!),
              ),
              SizedBox(height: 16),
              if (taskType == 'learning') ...[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    prefixIcon: Icon(Icons.subject, color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter subject' : null,
                  onSaved: (value) => subject = value,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Topic',
                    prefixIcon: Icon(Icons.topic, color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter topic' : null,
                  onSaved: (value) => topic = value,
                ),
                SizedBox(height: 16),
              ],
              if (taskType == 'programming') ...[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Programming Topic',
                    prefixIcon: Icon(Icons.laptop_mac, color: Colors.deepPurple),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter programming topic' : null,
                  onSaved: (value) => topic = value,
                ),
                SizedBox(height: 16),
              ],
              Text('Target Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Hours',
                        prefixIcon: Icon(Icons.access_time, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '0',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        int? hours = int.tryParse(value);
                        if (hours == null || hours < 0) return 'Invalid';
                        return null;
                      },
                      onSaved: (value) => targetHours = int.tryParse(value ?? '0') ?? 0,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Minutes',
                        prefixIcon: Icon(Icons.timer, color: Colors.deepPurple),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      initialValue: '30',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        int? minutes = int.tryParse(value);
                        if (minutes == null || minutes < 0 || minutes >= 60) return 'Invalid';
                        return null;
                      },
                      onSaved: (value) => targetMinutes = int.tryParse(value ?? '30') ?? 30,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    try {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        if (targetHours == 0 && targetMinutes == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Please set a target time of at least 1 minute'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        final task = Task(
                          title: title,
                          description: description,
                          taskType: taskType,
                          subject: subject,
                          topic: topic,
                          targetHours: targetHours,
                          targetMinutes: targetMinutes,
                          startTime: DateTime.now(),
                        );
                        Navigator.pop(context, task);
                      }
                    } catch (e) {
                      print('Error creating task: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error creating task'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Start Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// TASK CARD
// ============================================================================

class TaskCard extends StatefulWidget {
  final Task task;
  final DateTime currentTime;
  final VoidCallback onComplete;
  final VoidCallback onFailed;

  TaskCard({required this.task, required this.currentTime, required this.onComplete, required this.onFailed});

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  Timer? _timer;
  DateTime currentTime = DateTime.now();
  bool hasShownWarning = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    try {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (!_isDisposed && mounted) {
          try {
            setState(() {
              currentTime = DateTime.now();
              _checkTimeStatus();
            });
          } catch (e) {
            print('Error in timer: $e');
            timer.cancel();
          }
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print('Error starting timer: $e');
    }
  }

  void _checkTimeStatus() {
    try {
      int remainingSeconds = widget.task.getRemainingSeconds(currentTime);

      if (remainingSeconds < 1800 && remainingSeconds > 0 && !hasShownWarning &&
          !widget.task.isCompleted && !widget.task.isFailed) {
        hasShownWarning = true;
        _showWarningDialog();
      }

      if (remainingSeconds <= 0 && !widget.task.isCompleted && !widget.task.isFailed) {
        widget.onFailed();
        _timer?.cancel();
        _showFailureDialog();
      }
    } catch (e) {
      print('Error checking time status: $e');
    }
  }

  void _showWarningDialog() {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade400, Colors.red.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white, size: 60),
                SizedBox(height: 16),
                Text('LOW TIME!', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('HURRY UP! Less than 30 minutes remaining!',
                    style: TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
                SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text('Got it!', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing warning dialog: $e');
    }
  }

  void _showFailureDialog() {
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black87,
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel, color: Colors.red, size: 80),
                SizedBox(height: 16),
                Text('YOU FAILED', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                SizedBox(height: 12),
                Text('Time is up! Task not completed on time.',
                    style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  onPressed: () {
                    if (mounted) Navigator.pop(context);
                  },
                  child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      print('Error showing failure dialog: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    super.dispose();
  }

  Color _getCardColor() {
    try {
      if (widget.task.isFailed) return Colors.black87;
      if (widget.task.isCompleted) return Colors.green.shade50;
      int remainingSeconds = widget.task.getRemainingSeconds(currentTime);
      if (remainingSeconds < 1800 && remainingSeconds > 0) return Colors.red.shade50;
      return Colors.white;
    } catch (e) {
      print('Error getting card color: $e');
      return Colors.white;
    }
  }

  String _formatTime(int seconds) {
    try {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int secs = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } catch (e) {
      print('Error formatting time: $e');
      return '00:00:00';
    }
  }

  IconData _getTaskIcon() {
    switch (widget.task.taskType) {
      case 'learning': return Icons.school;
      case 'programming': return Icons.code;
      case 'writing': return Icons.edit;
      default: return Icons.task;
    }
  }

  Color _getTaskTypeColor() {
    switch (widget.task.taskType) {
      case 'learning': return Colors.blue;
      case 'programming': return Colors.green;
      case 'writing': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    int remainingSeconds = widget.task.getRemainingSeconds(currentTime);
    bool showWarning = remainingSeconds < 1800 && remainingSeconds > 0 &&
        !widget.task.isCompleted && !widget.task.isFailed;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      color: _getCardColor(),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(widget.task.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: widget.task.isFailed ? Colors.white : Colors.black)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.task.isFailed ? Colors.red :
                    (widget.task.isCompleted ? Colors.green : _getTaskTypeColor()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(children: [
                    Icon(_getTaskIcon(), color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(widget.task.taskType.toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(widget.task.description,
                style: TextStyle(color: widget.task.isFailed ? Colors.white70 : Colors.grey.shade700)),
            if (widget.task.subject != null) ...[
              SizedBox(height: 4),
              Text('Subject: ${widget.task.subject}',
                  style: TextStyle(fontSize: 12, color: widget.task.isFailed ? Colors.white60 : Colors.grey.shade600)),
            ],
            if (widget.task.topic != null) ...[
              SizedBox(height: 4),
              Text('Topic: ${widget.task.topic}',
                  style: TextStyle(fontSize: 12, color: widget.task.isFailed ? Colors.white60 : Colors.grey.shade600)),
            ],
            SizedBox(height: 12),
            if (!widget.task.isCompleted && !widget.task.isFailed)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: showWarning
                        ? [Colors.red.shade600, Colors.red.shade800]
                        : [Colors.blue.shade600, Colors.blue.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      Icon(Icons.timer, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Time Left:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ]),
                    Text(_formatTime(remainingSeconds > 0 ? remainingSeconds : 0),
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
              ),
            if (showWarning)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('⚠️ LOW TIME! HURRY UP!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            if (widget.task.isFailed)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text('FAILED', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            if (widget.task.isCompleted)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade500, Colors.green.shade700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text('✓ COMPLETED',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ),
              ),
            if (!widget.task.isCompleted && !widget.task.isFailed)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: widget.onComplete,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Complete Task', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// PROFILE SCREEN
// ============================================================================

class ProfileScreen extends StatelessWidget {
  final int lifetimeFailures;
  final int totalTasks;
  final int completedTasks;

  ProfileScreen({required this.lifetimeFailures, required this.totalTasks, required this.completedTasks});

  @override
  Widget build(BuildContext context) {
    int successRate = totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.red.shade600],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade200,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(children: [
                Icon(Icons.warning_amber_rounded, size: 70, color: Colors.white),
                SizedBox(height: 16),
                Text('Lifetime Failures',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 12),
                Text('$lifetimeFailures',
                    style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 8),
                Text('Tasks not completed on time',
                    style: TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
              ]),
            ),
            SizedBox(height: 24),
            Text('Statistics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            SizedBox(height: 16),
            _buildStatCard(Icons.task, 'Total Tasks', '$totalTasks', Colors.blue),
            _buildStatCard(Icons.check_circle, 'Completed', '$completedTasks', Colors.green),
            _buildStatCard(Icons.cancel, 'Failed', '$lifetimeFailures', Colors.red),
            _buildStatCard(Icons.percent, 'Success Rate', '$successRate%', Colors.purple),
            SizedBox(height: 24),
            if (lifetimeFailures > 0)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade400],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(Icons.lightbulb, color: Colors.white, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Learn from failures! Every setback is a setup for a comeback.',
                      style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String title, String value, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

// ============================================================================
// AI CHECKER SCREEN
// ============================================================================

class AICheckerScreen extends StatefulWidget {
  final Task task;

  AICheckerScreen({required this.task});

  @override
  _AICheckerScreenState createState() => _AICheckerScreenState();
}

class _AICheckerScreenState extends State<AICheckerScreen> {
  final TextEditingController _answerController = TextEditingController();
  bool isChecking = false;
  bool? isPassed;
  String? feedback;
  String question = '';

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _generateQuestion() {
    try {
      if (widget.task.taskType == 'learning') {
        question = 'Explain the main concepts you learned about "${widget.task.topic}" in ${widget.task.subject}.';
      } else if (widget.task.taskType == 'programming') {
        question = 'Write a simple program or code snippet demonstrating "${widget.task.topic}".';
      }
    } catch (e) {
      print('Error generating question: $e');
      question = 'Explain what you learned.';
    }
  }

  Future<void> _checkAnswer() async {
    try {
      if (_answerController.text.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please provide an answer'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() {
        isChecking = true;
        isPassed = null;
        feedback = null;
      });

      final result = await GeminiService.evaluateAnswer(
        question,
        _answerController.text,
        widget.task.topic ?? 'the topic',
      );

      if (mounted) {
        setState(() {
          isPassed = result['passed'];
          feedback = result['feedback'];
          isChecking = false;
        });

        if (isPassed == true) {
          await Future.delayed(Duration(seconds: 2));
          if (mounted) Navigator.pop(context, true);
        }
      }
    } catch (e) {
      print('Error checking answer: $e');
      if (mounted) {
        setState(() {
          isChecking = false;
          isPassed = _answerController.text.length >= 50;
          feedback = isPassed == true
              ? 'Your answer demonstrates understanding of the topic.'
              : 'Your answer is too brief. Please provide more detail.';
        });

        if (isPassed == true) {
          await Future.delayed(Duration(seconds: 2));
          if (mounted) Navigator.pop(context, true);
        }
      }
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('Knowledge Check', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.assignment, color: Colors.blue.shade700, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(widget.task.title,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                    ),
                  ]),
                  if (widget.task.topic != null) ...[
                    SizedBox(height: 8),
                    Text('Topic: ${widget.task.topic}', style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ],
              ),
            ),
            SizedBox(height: 24),
            Text('Question:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(question, style: TextStyle(fontSize: 16, height: 1.5)),
            ),
            SizedBox(height: 24),
            Text('Your Answer:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
            SizedBox(height: 8),
            TextField(
              controller: _answerController,
              decoration: InputDecoration(
                hintText: widget.task.taskType == 'programming' ? 'Write your code here...' : 'Write your answer here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: widget.task.taskType == 'programming' ? 15 : 8,
              style: TextStyle(fontSize: 14, fontFamily: widget.task.taskType == 'programming' ? 'monospace' : null),
            ),
            SizedBox(height: 24),
            if (isPassed != null) ...[
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPassed!
                        ? [Colors.green.shade400, Colors.green.shade600]
                        : [Colors.red.shade400, Colors.red.shade600],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (isPassed! ? Colors.green : Colors.red).shade200,
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(children: [
                  Icon(isPassed! ? Icons.check_circle : Icons.cancel,
                      color: Colors.white, size: 60),
                  SizedBox(height: 12),
                  Text(isPassed! ? 'PASSED!' : 'FAILED',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 8),
                  Text(feedback ?? '', style: TextStyle(fontSize: 14, color: Colors.white), textAlign: TextAlign.center),
                ]),
              ),
              SizedBox(height: 16),
            ],
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isChecking
                      ? [Colors.grey.shade400, Colors.grey.shade600]
                      : [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isChecking || isPassed == true ? null : _checkAnswer,
                child: isChecking
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
                    SizedBox(width: 12),
                    Text('Checking with AI...', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Submit Answer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
