import 'dart:io';

import '../lib/src/core/gemini_client.dart';
import '../lib/src/models/generation_config.dart';

/// Demonstration of enhanced generateImage method that accepts both text and images
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  final client = GeminiClient();
  await client.initialize(apiKey: apiKey);

  try {
    print('🎨 === ENHANCED GENERATE IMAGE DEMO ===\n');

    // Example 1: Text-only image generation (original functionality)
    print('📝 1. Text-Only Image Generation');
    final textOnlyResponse = await client.generateImage(
      prompt: 'A futuristic robot cat with glowing blue eyes',
      config: const GenerationConfig(temperature: 0.8),
    );

    print('   ✅ Generated: ${textOnlyResponse.text}');

    if (textOnlyResponse.firstImage != null) {
      final file1 = File('example/generated_images/robot_cat_text_only.png');
      await file1.writeAsBytes(textOnlyResponse.firstImage!.data);
      print('   💾 Saved to: ${file1.path}\n');
    }

    // Example 2: Image-to-image generation (new functionality)
    print('🖼️ 2. Image-to-Image Generation');

    // Load an existing image as reference
    final catFile = File('example/generated_images/cat.png');
    if (await catFile.exists()) {
      final catBytes = await catFile.readAsBytes();

      final imageToImageResponse = await client.generateImage(
        prompt:
            'Transform this cat into a cyberpunk style with neon colors and futuristic elements',
        images: [
          (data: catBytes, mimeType: 'image/png'),
        ],
        config: const GenerationConfig(temperature: 0.9),
      );

      print('   ✅ Generated: ${imageToImageResponse.text}');

      if (imageToImageResponse.firstImage != null) {
        final file2 =
            File('example/generated_images/cyberpunk_cat_variation.png');
        await file2.writeAsBytes(imageToImageResponse.firstImage!.data);
        print('   💾 Saved to: ${file2.path}\n');
      }
    } else {
      print(
          '   ⚠️ Reference cat.png not found, skipping image-to-image demo\n');
    }

    // Example 3: Multiple reference images
    print('🎭 3. Multiple Reference Images');

    final robotFile = File('example/generated_images/robot_cat_text_only.png');
    if (await catFile.exists() && await robotFile.exists()) {
      final catBytes = await catFile.readAsBytes();
      final robotBytes = await robotFile.readAsBytes();

      final multiImageResponse = await client.generateImage(
        prompt:
            'Combine the style of these two images to create a new artistic interpretation',
        images: [
          (data: catBytes, mimeType: 'image/png'),
          (data: robotBytes, mimeType: 'image/png'),
        ],
        config: const GenerationConfig(temperature: 0.7),
      );

      print('   ✅ Generated: ${multiImageResponse.text}');

      if (multiImageResponse.firstImage != null) {
        final file3 = File('example/generated_images/combined_style_cat.png');
        await file3.writeAsBytes(multiImageResponse.firstImage!.data);
        print('   💾 Saved to: ${file3.path}\n');
      }
    } else {
      print('   ⚠️ Reference images not found, skipping multi-image demo\n');
    }

    print('✅ Enhanced generateImage demo completed!');
    print('🎯 Key Features Demonstrated:');
    print('   • Text-only image generation (original)');
    print('   • Image-to-image transformation (new)');
    print('   • Multiple reference images (new)');
    print('   • Style transfer and variations (new)');
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}
