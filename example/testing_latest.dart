import 'dart:io';

// ✅ Single import - GeminiFile now available from main export!
import 'package:gemini_dart/gemini_dart.dart';

/// Example demonstrating the new capability-based model system
void main() async {
  // Get your API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  try {
    print('🧪 === TESTING createMultiModalPrompt ===');

    // Test 1: Text-only with multimodal model (should work)
    print('\n1️⃣ Testing text-only with multimodal model...');
    final multiModalClient = GeminiClient(model: GeminiModels.gemini15Pro);
    await multiModalClient.initialize(apiKey: apiKey);

    final textOnlyResponse = await multiModalClient.createMultiModalPrompt(
      text: 'Write a haiku about coding',
    );
    print('✅ Text-only response: ${textOnlyResponse.text}');

    // Test 2: Text-only with image generation model (should work for text)
    print('\n2️⃣ Testing text-only with image generation model...');
    final imageClient =
        GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await imageClient.initialize(apiKey: apiKey);

    final imageModelTextResponse = await imageClient.createMultiModalPrompt(
      text: 'Explain quantum computing in simple terms',
    );
    print('✅ Image model text response: ${imageModelTextResponse.text}');

    // Test 3: Empty call (should fail)
    print('\n3️⃣ Testing empty call (should fail)...');
    try {
      await imageClient.createMultiModalPrompt();
      print('❌ ERROR: This should have failed!');
    } catch (e) {
      print('✅ Correctly caught error: $e');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}
