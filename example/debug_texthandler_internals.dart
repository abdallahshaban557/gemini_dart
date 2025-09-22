import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug TextHandler internal request building
void main() async {
  final auth = AuthenticationHandler();
  final apiKey = Platform.environment['GEMINI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY environment variable is not set.');
    exit(1);
  }

  auth.setApiKey(apiKey);
  const config = GeminiConfig();
  final httpService = HttpService(auth: auth, config: config);

  try {
    print('=== Replicating TextHandler Internal Logic ===');

    // Replicate exactly what TextHandler does
    final contents = [TextContent('Explain quantum computing in simple terms')];
    const generationConfig = GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 100,
    );

    // Build request body like TextHandler does
    final body = <String, dynamic>{};

    // Single message format (no conversation context)
    body['contents'] = [
      {
        'parts': contents.map((content) {
          if (content is TextContent) {
            return {'text': content.text};
          } else {
            throw Exception('Unsupported content type');
          }
        }).toList(),
      }
    ];

    // Add generation config
    body['generationConfig'] = generationConfig.toJson();

    print('Request body:');
    print(body);

    // Make the API call
    print('\nMaking API call...');
    try {
      final response = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: body,
      );

      print('✅ API call successful');

      // Parse the response like TextHandler does
      print('Parsing response...');
      final geminiResponse = GeminiResponse.fromJson(response);
      print('✅ Response parsing successful');
      print('Text: ${geminiResponse.text}');
    } catch (e, stackTrace) {
      print('❌ Failed: $e');
      print('Stack trace: $stackTrace');
    }
  } finally {
    httpService.dispose();
  }
}
