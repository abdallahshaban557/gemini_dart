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

    final testing = await imageClient.createMultiModalPrompt(
      text: 'Generate an image of a cute cat',
      images: [
        (
          data: File('example/generated_images/cat.png').readAsBytesSync(),
          mimeType: 'image/png'
        ),
      ],
      config: const GenerationConfig(
        temperature: 0.8,
      ),
    );

    print('📝 Response: ${testing.images.first.data}');

    //stop here
    exit(1);
  } catch (e) {
    print('❌ Error: $e');
  }
}
