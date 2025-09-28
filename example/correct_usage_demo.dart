import 'package:gemini_dart/gemini_dart.dart';

/// Demo showing the CORRECT way to use model-specific clients
void main() {
  print('🎯 === CORRECT USAGE - MODEL-SPECIFIC CLIENTS ===\n');

  print('✅ CORRECT: Use specific factory functions for perfect IntelliSense\n');

  // Example 1: Text-only model
  print('📝 1. Text-Only Model:');
  print('   ```dart');
  print('   final client = createGemini15FlashClient();');
  print('   await client.generateText(prompt: "Hello");        // ✅ Appears');
  print('   await client.generateTextStream(prompt: "Hello");  // ✅ Appears');
  print(
      '   // client.generateImage(...);                      // ❌ Compile error!');
  print('   ```');

  final textClient = createGemini15FlashClient();
  print('   🎯 Type: ${textClient.runtimeType}');
  print('   🎯 Interface: BaseGeminiClient (text methods only)');
  print('');

  // Example 2: Image generation model
  print('🎨 2. Image Generation Model:');
  print('   ```dart');
  print('   final client = createGemini25FlashImagePreviewClient();');
  print('   await client.generateText(prompt: "Hello");        // ✅ Appears');
  print('   await client.generateImage(prompt: "A sunset");    // ✅ Appears');
  print('   await client.createMultiModalPrompt(...);          // ✅ Appears');
  print(
      '   // client.analyzeImage(...);                       // ❌ Compile error!');
  print('   ```');

  final imageClient = createGemini25FlashImagePreviewClient();
  print('   🎯 Type: ${imageClient.runtimeType}');
  print('   🎯 Interface: ImageGenerationCapable (text + image generation)');
  print('');

  // Example 3: Multi-modal analysis model
  print('👁️ 3. Multi-Modal Analysis Model:');
  print('   ```dart');
  print('   final client = createGemini15ProClient();');
  print('   await client.generateText(prompt: "Hello");        // ✅ Appears');
  print(
      '   await client.analyzeImage(prompt: "What is this?", images: [...]);  // ✅ Appears');
  print('   await client.analyzeDocument(...);                 // ✅ Appears');
  print('   await client.analyzeVideo(...);                    // ✅ Appears');
  print(
      '   // client.generateImage(...);                      // ❌ Compile error!');
  print('   ```');

  final analysisClient = createGemini15ProClient();
  print('   🎯 Type: ${analysisClient.runtimeType}');
  print('   🎯 Interface: AnalysisCapable (text + analysis methods)');
  print('');

  print('🚀 === KEY BENEFITS ===');
  print('✅ Perfect IntelliSense - only see methods you can use');
  print('✅ Compile-time safety - impossible to call unsupported methods');
  print('✅ Clear intent - factory function name tells you what the model does');
  print('✅ No casting needed - everything is properly typed');
  print('');

  print('💡 === USAGE PATTERN ===');
  print('1. Pick the right factory function for your model:');
  print('   • createGemini15FlashClient() → Text only');
  print(
      '   • createGemini25FlashImagePreviewClient() → Text + Image generation');
  print('   • createGemini15ProClient() → Text + Analysis');
  print('');
  print('2. Use the returned client with perfect IntelliSense');
  print('3. Only supported methods appear - no guessing!');
  print('');

  print('🎉 This is exactly the behavior you wanted!');
  print('   Methods only appear for models that support them! 🎯✨');
}
