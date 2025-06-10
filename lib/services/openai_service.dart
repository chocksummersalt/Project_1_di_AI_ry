import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';
  late final String _apiKey;

  OpenAIService() {
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  }

  Future<String> processFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-vision-preview',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Please analyze this file and provide a summary.'
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64File'
                  }
                }
              ]
            }
          ],
          'max_tokens': 300
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('Failed to process file: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing file: $e');
    }
  }
} 