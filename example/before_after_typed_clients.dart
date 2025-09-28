import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Comparison showing before/after developer experience with typed clients
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  print('🔄 === BEFORE vs AFTER: TYPED CLIENTS ===\n');

  try {
    print('❌ BEFORE (Manual capability checking):');
    print('```dart');
    print('// You had to check capabilities manually');
    print('final client = GeminiClient(model: someModel);');
    print('await client.initialize(apiKey: apiKey);');
    print('');
    print('// Check before using - might fail at runtime!');
    print('if (client.selectedModel?.canGenerateImages == true) {');
    print('  await client.generateImage(prompt: "A sunset");');
    print('} else {');
    print('  throw Exception("Model doesn\'t support image generation");');
    print('}');
    print('');
    print('// All methods exist but might throw runtime errors');
    print('await client.analyzeVideo(...); // Might throw!');
    print('```');
    print('');
    print('Issues with old approach:');
    print('• ❌ Runtime errors if you forget to check capabilities');
    print('• ❌ All methods visible in IDE even if not supported');
    print('• ❌ Manual capability checking required');
    print('• ❌ Easy to make mistakes');
    print('• ❌ Confusing developer experience');
    print('');

    print('✅ AFTER (APIs light up automatically):');
    print('```dart');
    print('// Pick the right client type - APIs light up automatically!');
    print('final client = GeminiClientFactory.createImageGenerationClient();');
    print('await client.initialize(apiKey: apiKey);');
    print('');
    print('// These methods are guaranteed to exist and work:');
    print('await client.generateText(prompt: "Hello");     // ✅ Always works');
    print('await client.generateImage(prompt: "A sunset"); // ✅ Always works');
    print('');
    print('// These methods don\'t exist - compile error:');
    print('// await client.analyzeVideo(...); // ← Compile error!');
    print('```');
    print('');
    print('Benefits of new approach:');
    print('• ✅ Compile-time safety - wrong methods don\'t exist');
    print('• ✅ Clean IDE experience - only see relevant methods');
    print('• ✅ Zero capability checking needed');
    print('• ✅ No runtime errors from unsupported operations');
    print('• ✅ Clear separation by model capabilities');
    print('');

    // Demonstrate the difference with real code
    print('🧪 REAL EXAMPLE COMPARISON:');
    print('');

    // Old way simulation (using regular client)
    print('❌ Old way - manual checking:');
    final oldClient =
        GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await oldClient.initialize(apiKey: apiKey);

    // You had to check manually
    if (oldClient.selectedModel?.canGenerateImages == true) {
      final response =
          await oldClient.generateImage(prompt: 'A simple test image');
      print('   ✅ Image generation worked (after manual check)');
      print('   🖼️ Generated: ${response.images.length} images');
    } else {
      print('   ❌ Would have failed - model doesn\'t support images');
    }
    oldClient.dispose();

    // New way - automatic
    print('✅ New way - automatic API availability:');
    final newClient = GeminiClientFactory.createImageGenerationClient();
    await newClient.initialize(apiKey: apiKey);

    // No checking needed - method is guaranteed to exist and work
    final response =
        await newClient.generateImage(prompt: 'A simple test image');
    print('   ✅ Image generation just works (no checking needed)');
    print('   🖼️ Generated: ${response.images.length} images');

    // This would be a compile error:
    // newClient.analyzeVideo(...); // ← IDE shows error immediately

    newClient.dispose();
    print('');

    print('🎯 DEVELOPER EXPERIENCE COMPARISON:');
    print('');
    print('❌ Old IDE Experience:');
    print('   • See ALL methods even if not supported');
    print('   • Have to remember to check capabilities');
    print('   • Runtime errors if you forget');
    print('   • Confusing - which methods actually work?');
    print('');
    print('✅ New IDE Experience:');
    print('   • Only see methods that actually work');
    print('   • No capability checking needed');
    print('   • Compile-time errors prevent mistakes');
    print('   • Crystal clear - if method exists, it works!');
    print('');

    print('🚀 USAGE PATTERNS:');
    print('');
    print('📝 For text generation:');
    print('   final client = GeminiClientFactory.createTextOnlyClient();');
    print('   // Only text methods available');
    print('');
    print('🎨 For image generation:');
    print(
        '   final client = GeminiClientFactory.createImageGenerationClient();');
    print('   // Text + image generation methods available');
    print('');
    print('👁️ For image/video/document analysis:');
    print('   final client = GeminiClientFactory.createMultiModalClient();');
    print('   // Text + analysis methods available');
    print('');
    print('🤖 Don\'t know which? Let the factory decide:');
    print(
        '   final client = GeminiClientFactory.createClient(model: yourModel);');
    print('   // Automatically picks the right client type');
    print('');

    print('🎉 CONCLUSION:');
    print('✅ APIs now light up automatically based on model selection');
    print('✅ No more capability discovery or manual checking');
    print('✅ Compile-time safety prevents runtime errors');
    print('✅ Clean, intuitive developer experience');
    print('✅ Just pick the right client type and everything works!');
  } catch (e) {
    print('❌ Demo failed: $e');
  }
}
