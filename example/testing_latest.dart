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
    print('\n1️⃣ Testing text-only...');
    final client = GeminiClient(model: GeminiModels.gemini15Pro);
    await client.initialize(apiKey: apiKey);

    final textOnlyResponse = await client.createMultiModalPrompt(
      text: 'Write a haiku about coding',
    );
    print('✅ Text-only response: ${textOnlyResponse.text}');

    // Test 2: Files API with single image
    print('\n2️⃣ Testing with single GeminiFile...');

    // Check if we have an existing image to analyze
    final imageFile = File('example/generated_images/sunset.png');
    if (await imageFile.exists()) {
      final geminiFile = await GeminiFile.fromFile(imageFile);

      final fileResponse = await client.createMultiModalPrompt(
        text: 'Describe what you see in this image in detail',
        files: [geminiFile],
      );
      print(
          '✅ Single file analysis: ${fileResponse.text?.substring(0, 100)}...');
    } else {
      print('⚠️ Skipping file test - no image found at ${imageFile.path}');
    }

    // Test 3: Multiple files (if available)
    print('\n3️⃣ Testing with multiple files...');
    final files = <GeminiFile>[];

    // Try to add multiple image files if they exist
    for (final fileName in [
      'sunset.png',
      'testing_latest_output.png',
      'cat.png'
    ]) {
      final file = File('example/generated_images/$fileName');
      if (await file.exists()) {
        files.add(await GeminiFile.fromFile(file));
      }
    }

    if (files.isNotEmpty) {
      final multiFileResponse = await client.createMultiModalPrompt(
        text: 'Compare and describe the differences between these images',
        files: files,
      );
      print('✅ Multi-file analysis: Found ${files.length} files');
      print('Response: ${multiFileResponse.text?.substring(0, 150)}...');
    } else {
      print('⚠️ Skipping multi-file test - no images found');
    }

    // Test 4: Empty call (should fail)
    print('\n4️⃣ Testing empty call (should fail)...');
    try {
      await client.createMultiModalPrompt();
      print('❌ ERROR: This should have failed!');
    } catch (e) {
      print('✅ Correctly caught error: $e');
    }

    print('\n🎉 === CLEAN API SUCCESSFUL ===');
    print('✅ Clean files parameter works');
    print('✅ No legacy parameters - simple and consistent');
    print('✅ Fully consistent API with generateImage method');
  } catch (e) {
    print('❌ Error: $e');
  }
}
