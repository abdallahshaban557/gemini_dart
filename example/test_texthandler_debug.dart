import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug TextHandler specifically with gemini-2.5-flash
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
    print('=== Testing TextHandler with gemini-2.5-flash ===');

    final textHandler =
        TextHandler(httpService: httpService, model: 'gemini-2.5-flash');

    // Test 1: Basic generation without config
    print('Test 1: Basic generation...');
    try {
      final response = await textHandler.generateContent('Say hello');
      print('✅ Basic generation works');
      print('Response: ${response.text}');
    } catch (e, stackTrace) {
      print('❌ Basic generation failed: $e');
      print('Stack trace: $stackTrace');
    }

    // Test 2: Generation with config
    print('\nTest 2: Generation with config...');
    try {
      const generationConfig = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 50,
      );

      final response = await textHandler.generateContent(
        'Write a short greeting',
        config: generationConfig,
      );
      print('✅ Generation with config works');
      print('Response: ${response.text}');
      print('Tokens: ${response.usageMetadata?.totalTokenCount}');
    } catch (e, stackTrace) {
      print('❌ Generation with config failed: $e');
      print('Stack trace: $stackTrace');
    }

    // Test 3: Compare with gemini-1.5-flash
    print('\nTest 3: Comparing with gemini-1.5-flash...');
    try {
      final textHandler15 =
          TextHandler(httpService: httpService, model: 'gemini-1.5-flash');

      const generationConfig = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 50,
      );

      final response = await textHandler15.generateContent(
        'Write a short greeting',
        config: generationConfig,
      );
      print('✅ gemini-1.5-flash works');
      print('Response: ${response.text}');
      print('Tokens: ${response.usageMetadata?.totalTokenCount}');
    } catch (e, stackTrace) {
      print('❌ gemini-1.5-flash failed: $e');
      print('Stack trace: $stackTrace');
    }
  } finally {
    httpService.dispose();
  }
}
