import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Simple example of using the Gemini API
void main() async {
  // Get your API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  // Initialize the client
  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    // Generate text using generateText
    print('🔄 Generating text...');
    final result = await client.generateText(
      prompt: 'Write a haiku about programming',
      config: const GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 100,
      ),
    );

    print('✅ Result: ${result.text}');

    // Generate content using generateFromContent
    print('\n🔄 Generating content from Content objects...');
    final contentResult = await client.generateFromContent(
      contents: [
        TextContent('Explain what machine learning is in simple terms')
      ],
      config: const GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 150,
      ),
    );

    print('✅ Content result: ${contentResult.text}');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Always dispose the client
    client.dispose();
  }
}
