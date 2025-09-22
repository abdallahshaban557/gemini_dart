import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug the specific issue with the second call in the main example
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
    final textHandler =
        TextHandler(httpService: httpService, model: 'gemini-2.5-flash');

    print('=== Replicating Main Example Sequence ===');

    // Step 1: First call (same as main example)
    print('Step 1: Basic text generation...');
    try {
      final response1 = await textHandler.generateContent(
        'Write a short poem about artificial intelligence',
      );
      print('✅ First call successful');
      print('Response length: ${response1.text?.length}');
      print('Tokens: ${response1.usageMetadata?.totalTokenCount}');
    } catch (e) {
      print('❌ First call failed: $e');
      return;
    }

    // Step 2: Second call with config (same as main example)
    print('\nStep 2: Text generation with configuration...');
    try {
      const generationConfig = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 100,
      );

      final response2 = await textHandler.generateContent(
        'Explain quantum computing in simple terms',
        config: generationConfig,
      );
      print('✅ Second call successful');
      print('Response: ${response2.text}');
    } catch (e, stackTrace) {
      print('❌ Second call failed: $e');
      print('Stack trace: $stackTrace');

      // Let's try the same call with a fresh TextHandler
      print('\nTrying with fresh TextHandler...');
      try {
        final freshTextHandler =
            TextHandler(httpService: httpService, model: 'gemini-2.5-flash');
        const generationConfig = GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 100,
        );

        final response = await freshTextHandler.generateContent(
          'Explain quantum computing in simple terms',
          config: generationConfig,
        );
        print('✅ Fresh TextHandler works');
        print('Response: ${response.text}');
      } catch (freshError) {
        print('❌ Fresh TextHandler also failed: $freshError');
      }
    }
  } finally {
    httpService.dispose();
  }
}
