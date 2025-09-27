import 'dart:convert';
import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Example using model selection in constructor
void main() async {
  // Get your API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  try {
    // Example 1: Image generation model
    print('🎨 === IMAGE GENERATION MODEL ===');
    final imageClient =
        GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await imageClient.initialize(apiKey: apiKey);

    // Try using the dedicated generateImage method
    final testing = await imageClient.generateImage(
      prompt: 'Generate an image of a cute cat',
      config: const GenerationConfig(
        temperature: 0.8,
      ),
    );

    print('📝 Response: ${testing.text}');
    print('🖼️ Has images: ${testing.hasImages}');
    print('📊 Number of images: ${testing.images.length}');

    if (testing.hasImages && testing.images.isNotEmpty) {
      final file = File('example/generated_images/cat.png');
      await file.writeAsBytes(testing.images.first.data);
      print('🎉 Image saved: ${file.path}');
      print(
          '📏 Size: ${(testing.images.first.data.length / 1024 / 1024).toStringAsFixed(1)} MB');
    } else {
      print('⚠️ No images were generated');
    }

    imageClient.dispose();
  } catch (e) {
    print('❌ Error: $e');
  }
}
