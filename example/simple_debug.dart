import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Simple debug script for testing gemini-2.5-flash model
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
    print('=== Testing gemini-2.5-flash ===');

    // Test 1: Basic model availability
    try {
      final response = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Hello, what model are you?'}
              ]
            }
          ]
        },
      );
      print('✅ gemini-2.5-flash is available');
      print(
          'Response: ${response['candidates'][0]['content']['parts'][0]['text']}');
    } catch (e) {
      print('❌ gemini-2.5-flash failed: $e');
      return;
    }

    print('\n=== Testing Configuration Options ===');

    // Test 2: Temperature configuration
    try {
      final response = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Write a creative sentence about space.'}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.9, 'maxOutputTokens': 50}
        },
      );
      print('✅ Temperature config works');
      print(
          'Response: ${response['candidates'][0]['content']['parts'][0]['text']}');
    } catch (e) {
      print('❌ Temperature config failed: $e');
    }

    // Test 3: Using TextHandler
    print('\n=== Testing TextHandler ===');
    try {
      final textHandler =
          TextHandler(httpService: httpService, model: 'gemini-2.5-flash');

      const generationConfig = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 100,
      );

      final response = await textHandler.generateContent(
        'Explain AI in simple terms',
        config: generationConfig,
      );

      print('✅ TextHandler works with gemini-2.5-flash');
      print('Response: ${response.text}');
      print('Tokens: ${response.usageMetadata?.totalTokenCount}');
    } catch (e) {
      print('❌ TextHandler failed: $e');
    }
  } finally {
    httpService.dispose();
  }
}
