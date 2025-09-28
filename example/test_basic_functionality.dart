import 'dart:io';

import 'package:gemini_dart/src/core/gemini_client.dart';
import 'package:gemini_dart/src/models/generation_config.dart';

/// Test basic GeminiClient functionality after removing capability logic
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  try {
    print('🧪 === TESTING BASIC GEMINI CLIENT ===');

    // Test 1: Basic text generation
    print('\n📝 1. Testing text generation...');
    final client = GeminiClient();
    await client.initialize(apiKey: apiKey);

    final textResponse = await client.generateText(
      prompt: 'Say hello in a creative way',
      config: const GenerationConfig(temperature: 0.7),
    );

    print('✅ Text generation works: ${textResponse.text}');

    // Test 2: Image generation (should work with any client now)
    print('\n🎨 2. Testing image generation...');
    final imageResponse = await client.generateImage(
      prompt: 'A simple geometric pattern',
    );

    print('✅ Image generation works: ${imageResponse.text}');

    if (imageResponse.firstImage != null) {
      final file = File('example/generated_images/basic_test.png');
      await file.writeAsBytes(imageResponse.firstImage!.data);
      print('💾 Image saved to: ${file.path}');
    }

    // Test 3: Multi-modal prompt
    print('\n🔍 3. Testing multi-modal prompt...');
    final multiResponse = await client.createMultiModalPrompt(
      text: 'Describe this concept: simplicity',
    );

    print('✅ Multi-modal works: ${multiResponse.text}');

    client.dispose();
    print('\n🎉 All basic functionality tests passed!');
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }
}
