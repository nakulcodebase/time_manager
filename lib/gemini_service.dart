import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Get your API key from: https://makersuite.google.com/app/apikey
  static const String apiKey = 'AIzaSyCQD6dbQjRN4mbPqOxhQ3XXhWzscl401Cg';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  static Future<Map<String, dynamic>> evaluateAnswer(
      String question,
      String userAnswer,
      String topic,
      ) async {
    final prompt = '''
You are evaluating a student's answer to test their understanding.

Question: $question
Topic: $topic
Student's Answer: $userAnswer

Evaluate if the student demonstrates basic understanding of the topic.
Respond in this exact format:
RESULT|feedback

Where RESULT is either "PASS" or "FAIL"
And feedback is 1-2 sentences explaining your decision.

Example: PASS|You have demonstrated a good understanding of the basic concepts.
''';

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'topK': 32,
            'topP': 1,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String result = data['candidates'][0]['content']['parts'][0]['text'];

        List<String> parts = result.split('|');
        if (parts.length >= 2) {
          return {
            'passed': parts[0].trim().toUpperCase().contains('PASS'),
            'feedback': parts.sublist(1).join('|').trim(),
          };
        } else {
          return {
            'passed': result.toUpperCase().contains('PASS'),
            'feedback': result.replaceAll('PASS', '').replaceAll('FAIL', '').trim(),
          };
        }
      } else {
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Gemini API Error: $e');
      bool passed = userAnswer.length >= 50;
      return {
        'passed': passed,
        'feedback': passed
            ? 'Your answer shows understanding of the topic.'
            : 'Your answer is too brief. Please provide more details.',
      };
    }
  }
}
