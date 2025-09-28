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

    //get file data from file
    final file = File('example/generated_images/cat.png');
    final fileData = await file.readAsBytes();

    final response = await client.generateImage(
      prompt: 'add wings and have it be flying with a sunset background',
      geminiFiles: [GeminiFile(data: fileData, fileType: GeminiFileType.png)],
    );

    //save image to file
    final file1 = File('example/generated_images/cat_with_wings.png');
    await file1.writeAsBytes(response.firstImage!.data);
    print('💾 Image saved to: ${file.path}');

    print(response.text);
  } catch (e) {
    print('❌ Error: $e');
  }
}
