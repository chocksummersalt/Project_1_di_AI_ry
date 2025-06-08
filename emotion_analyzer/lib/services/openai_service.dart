import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/emotion_analysis.dart';

class OpenAIService {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1/chat/completions';

  OpenAIService({required this.apiKey});

  Future<EmotionAnalysis> analyzeEmotion(String text) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an emotion analysis expert. Analyze the following text and respond with the primary emotion and confidence score (0-1).'
            },
            {
              'role': 'user',
              'content': text
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        // Parse the response to extract emotion and confidence
        final parts = content.split(',');
        final emotion = parts[0].trim();
        final confidence = double.parse(parts[1].trim());

        return EmotionAnalysis(
          text: text,
          emotion: emotion,
          confidence: confidence,
        );
      } else {
        throw Exception('Failed to analyze emotion: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error analyzing emotion: $e');
    }
  }
} 