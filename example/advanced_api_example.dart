import 'dart:io';
import 'dart:typed_data';

import 'package:gemini_dart/gemini_dart.dart';

/// Advanced example demonstrating image analysis and file handling
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    await demonstrateImageAnalysis(client);
    await demonstrateFileUpload(client);
    await demonstrateAdvancedImageGeneration(client);
    await demonstrateCustomConfiguration(client);
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

/// Example: Analyze an image
Future<void> demonstrateImageAnalysis(GeminiClient client) async {
  print('🔍 === IMAGE ANALYSIS ===');

  // Create a simple test image (in real usage, you'd load an actual image file)
  // For this example, we'll create a minimal PNG data
  final testImageData = _createTestImageData();

  try {
    final result = await client.analyzeImage(
      testImageData,
      'image/png',
      prompt: 'Describe what you see in this image in detail',
      config: const GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 200,
      ),
    );

    print('✅ Image analysis result: ${result.text}');
  } catch (e) {
    print('⚠️ Image analysis failed: $e');
  }
}

/// Example: File upload for video content
Future<void> demonstrateFileUpload(GeminiClient client) async {
  print('\n📁 === FILE UPLOAD ===');

  // Create a temporary test file
  final tempFile = File('temp_test.txt');
  await tempFile.writeAsString('This is a test file for upload demonstration.');

  try {
    final uploadResult = await client.uploadFile(
      tempFile,
      mimeType: 'text/plain',
    );

    print('✅ File uploaded successfully!');
    print('📄 File URI: ${uploadResult.fileUri}');
    print('📏 Size: ${uploadResult.sizeBytes} bytes');
    print('🏷️ MIME type: ${uploadResult.mimeType}');

    // Clean up
    await tempFile.delete();
  } catch (e) {
    print('⚠️ File upload failed: $e');
    // Clean up on error
    if (await tempFile.exists()) {
      await tempFile.delete();
    }
  }
}

/// Example: Advanced image generation with custom options
Future<void> demonstrateAdvancedImageGeneration(GeminiClient client) async {
  print('\n🎨 === ADVANCED IMAGE GENERATION ===');

  try {
    // Generate image with specific aspect ratio and style
    final result = await client.generateImageAdvanced(
      'A cyberpunk cityscape with flying cars and neon lights',
      aspectRatio: '16:9',
      style: 'digital_art',
      seed: 42, // For reproducible results
      config: const GenerationConfig(
        temperature: 0.8,
      ),
    );

    print('✅ Advanced image generated!');
    print('📝 Description: ${result.text}');
  } catch (e) {
    print('⚠️ Advanced image generation failed: $e');
  }
}

/// Example: Custom configuration and error handling
Future<void> demonstrateCustomConfiguration(GeminiClient client) async {
  print('\n⚙️ === CUSTOM CONFIGURATION ===');

  // Create a custom configuration
  final customConfig = const GenerationConfig(
    temperature: 0.2, // Low temperature for more focused responses
    maxOutputTokens: 50,
    topP: 0.9,
    topK: 20,
  );

  try {
    final result = await client.generateText(
      prompt: 'Explain the concept of recursion in programming',
      config: customConfig,
    );

    print('✅ Custom config result: ${result.text}');
  } catch (e) {
    print('❌ Custom configuration failed: $e');
  }

  // Demonstrate error handling with invalid configuration
  try {
    final invalidConfig = const GenerationConfig(
      temperature: 2.0, // Invalid temperature (should be 0-1)
    );

    await client.generateText(
      prompt: 'This should fail',
      config: invalidConfig,
    );
  } catch (e) {
    print('✅ Error handling works: ${e.toString()}');
  }
}

/// Create minimal test image data (1x1 pixel PNG)
Uint8List _createTestImageData() {
  // This is a minimal 1x1 pixel PNG in base64
  const base64Data =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
  return Uint8List.fromList(base64Data.codeUnits);
}
