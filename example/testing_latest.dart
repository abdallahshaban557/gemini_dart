import 'dart:io';

// ✅ Single import - GeminiFile now available from main export!
import 'package:gemini_dart/gemini_dart.dart';

/// Example demonstrating the consolidated createMultiModalPrompt API
void main() async {
  // Get your API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  try {
    print('🧪 === TESTING CONSOLIDATED createMultiModalPrompt API ===');

    // Test 1: Text-only (should work)
    print('\n1️⃣ Testing image-generation...');
    final client = GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await client.initialize(apiKey: apiKey);

    final response = await client.generateImage(
      prompt: 'Create a beautiful sunset over mountains',
    );

    if (response.firstImage != null) {
      //save image to file
      final file = File('example/generated_images/sunset_mountains1.png');
      await file.writeAsBytes(response.firstImage!.data);
      print('💾 Image saved to: ${file.path}');
      print('🎉 Image generation successful!');
    } else {
      print('❌ No image found in response');
    }

    print('Response text: ${response.text}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
