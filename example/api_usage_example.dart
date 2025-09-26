import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Simple example demonstrating the Gemini API usage
void main() async {
  // Get API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  // Initialize the client
  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    // Example 1: Basic text generation
    print('📝 Generating text...');
    final textResult = await client.generateText(
      prompt: 'Write a haiku about programming',
      config: const GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 100,
      ),
    );
    print('✅ Result: ${textResult.text}\n');

    // Example 2: Image generation
    print('🎨 Generating image...');
    try {
      final imageResult = await client.generateImage(
        'A serene mountain landscape at sunset',
        config: const GenerationConfig(temperature: 0.8),
      );
      print('✅ Image generated: ${imageResult.text}\n');
    } catch (e) {
      print('⚠️ Image generation not available: $e\n');
    }

    // Example 3: Streaming text generation
    print('🌊 Streaming text generation...');
    await for (final chunk in client.generateTextStream(
      prompt: 'Tell me a short joke',
      config: const GenerationConfig(temperature: 0.9),
    )) {
      if (chunk.text?.isNotEmpty == true) {
        print(chunk.text!);
      }
    }
    print('\n✅ Streaming completed\n');

    // Example 4: Multi-modal content
    print('🖼️ Multi-modal content...');
    final contents = [
      TextContent('What are the main benefits of renewable energy?'),
    ];

    final multiModalResult = await client.generateFromContent(
      contents: contents,
      config: const GenerationConfig(
        temperature: 0.6,
        maxOutputTokens: 150,
      ),
    );
    print('✅ Multi-modal result: ${multiModalResult.text}\n');

    // Example 5: Conversation with context
    print('💬 Conversation with context...');
    final context = client.createConversationContext();

    // First message
    final firstResponse = await client.generateText(
      prompt: 'I want to learn about machine learning',
      config: const GenerationConfig(temperature: 0.7),
    );
    print('🤖 Assistant: ${firstResponse.text}');

    // Add to context
    context.addUserMessage('I want to learn about machine learning');
    context.addModelResponse(firstResponse);

    // Follow-up with context
    final followUpResponse = await client.generateText(
      prompt: 'What are the prerequisites?',
      config: const GenerationConfig(temperature: 0.7),
    );
    print('🤖 Assistant: ${followUpResponse.text}\n');

    // Example 6: Get available models
    print('📋 Available models:');
    try {
      final models = await client.getModels();
      for (final model in models.take(3)) {
        print('  - ${model.displayName}');
      }
    } catch (e) {
      print('⚠️ Could not fetch models: $e');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    // Always dispose the client
    client.dispose();
  }
}
