import 'dart:io';

// ✅ Single import - GeminiFile now available from main export!
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

    // Example 2: Multi-modal analysis model (can't generate images)
    final analysisClient = createGemini15ProClient();
    await analysisClient.initialize(apiKey: apiKey);
    
    // This would be a compile error - generateImage doesn't exist on AnalysisCapable:
    // final response = await analysisClient.generateImage(...); // ❌ Compile error!

    final testing = await imageClient.generateImage(
      prompt: 'Create a variation of this cat with wings',
      geminiFiles: [
        await GeminiFile.fromFile(File('example/generated_images/cat.png')),
      ],
      config: const GenerationConfig(temperature: 0.8),
    );

    final file = File('example/generated_images/testing_latest_output.png');
    await file.writeAsBytes(testing.images.first.data);
    print('💾 Image saved to: ${file.path}');

    //stop here
    exit(1);
  } catch (e) {
    print('❌ Error: $e');
  }
}
