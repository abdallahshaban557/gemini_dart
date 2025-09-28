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
    // Demonstrate capability checking
    print('🔍 === MODEL CAPABILITIES ===');

    // Check capabilities of different models
    final models = [
      GeminiModels.gemini15Flash,
      GeminiModels.gemini15Pro,
      GeminiModels.gemini25Flash,
      GeminiModels.gemini25FlashImagePreview,
    ];

    for (final model in models) {
      print('\n📋 ${model.name}:');
      print('  - Can generate text: ${model.canGenerateText}');
      print('  - Can generate images: ${model.canGenerateImages}');
      print('  - Can analyze images: ${model.canAnalyzeImages}');
      print('  - Can analyze videos: ${model.canAnalyzeVideos}');
      print('  - Can process audio: ${model.canProcessAudio}');
      print('  - Supports multimodal input: ${model.supportsMultiModalInput}');
      print(
          '  - Capabilities: ${model.capabilities.map((c) => c.description).join(', ')}');
    }

    // Find models by capability
    print('\n🔎 === MODELS BY CAPABILITY ===');
    print(
        'Text generation models: ${GeminiModels.textGenerationModels.map((m) => m.name).join(', ')}');
    print(
        'Image generation models: ${GeminiModels.imageGenerationModels.map((m) => m.name).join(', ')}');
    print(
        'Multimodal models: ${GeminiModels.multiModalModels.map((m) => m.name).join(', ')}');

    // Example 1: Image generation model
    print('\n🎨 === IMAGE GENERATION MODEL ===');
    final imageClient =
        GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await imageClient.initialize(apiKey: apiKey);

    // Example 2: Multi-modal analysis model
    final analysisClient = GeminiClient(model: GeminiModels.gemini15Pro);
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
