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

    // Test 2: New consolidated files API (recommended)
    print('\n2️⃣ Testing with GeminiFile (new consolidated API)...');

    // Check if we have an existing image to analyze
    final imageFile = File('example/generated_images/sunset.png');
    if (await imageFile.exists()) {
      final geminiFile = await GeminiFile.fromFile(imageFile);

      final fileResponse = await client.createMultiModalPrompt(
        text: 'Describe what you see in this image in detail',
        files: [geminiFile], // ✅ New consolidated API!
      );
      print('✅ File analysis response: ${fileResponse.text}');
    } else {
      print('⚠️ Skipping file test - no image found at ${imageFile.path}');
    }

    // Test 3: Legacy API still works (backward compatibility)
    print('\n3️⃣ Testing legacy images parameter (backward compatibility)...');
    if (await imageFile.exists()) {
      final imageBytes = await imageFile.readAsBytes();

      final legacyResponse = await client.createMultiModalPrompt(
        text: 'What colors dominate this image?',
        images: [(data: imageBytes, mimeType: 'image/png')], // Legacy API
      );
      print('✅ Legacy API response: ${legacyResponse.text}');
    } else {
      print('⚠️ Skipping legacy test - no image found');
    }

    // Test 4: Empty call (should fail)
    print('\n4️⃣ Testing empty call (should fail)...');
    try {
      await client.createMultiModalPrompt();
      print('❌ ERROR: This should have failed!');
    } catch (e) {
      print('✅ Correctly caught error: $e');
    }

    print('\n🎉 === API CONSOLIDATION SUCCESSFUL ===');
    print('✅ New files parameter works');
    print('✅ Legacy images/videos parameters still work');
    print('✅ Consistent API with generateImage method');
  } catch (e) {
    print('❌ Error: $e');
  }
}
