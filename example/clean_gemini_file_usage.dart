import 'dart:io';
import 'dart:typed_data';

// ✅ Single import - everything you need!
import 'package:gemini_dart/gemini_dart.dart';

/// Clean example showing GeminiFile usage with main package import
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  print('✨ === CLEAN GEMINI FILE USAGE ===\n');

  try {
    // Create client with automatic API version selection
    final client = GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
    await client.initialize(apiKey: apiKey);

    // Example 1: Create GeminiFile from existing file
    print('📁 1. Loading file with auto-detection:');
    final catFile = File('example/generated_images/cat.png');
    if (await catFile.exists()) {
      final imageFile = await GeminiFile.fromFile(catFile);
      print('   ✅ Loaded: $imageFile');
      print('   🏷️ Type: ${imageFile.fileType.description}');
      print('   📊 Size: ${imageFile.formattedSize}');
      print('');

      // Example 2: Use directly with generateImage (no toApiFormat needed!)
      print('🎨 2. Generating image with clean API:');
      final response = await client.generateImage(
        prompt:
            'Transform this cat into a magical wizard cat with a pointy hat and sparkles',
        geminiFiles: [imageFile], // ✅ Direct usage!
        config: const GenerationConfig(temperature: 0.8),
      );

      print('   🎨 Generated: ${response.text ?? "Image only"}');

      if (response.firstImage != null) {
        final outputFile = File('example/generated_images/wizard_cat.png');
        await outputFile.writeAsBytes(response.firstImage!.data);
        print('   💾 Saved wizard cat to: ${outputFile.path}');
      }
      print('');
    }

    // Example 3: Create GeminiFile with explicit type
    print('🔧 3. Creating file with explicit type:');
    final fakeImageData =
        Uint8List.fromList(List.generate(100, (i) => i % 256));
    final customFile = GeminiFile.fromBytes(
      bytes: fakeImageData,
      fileType: GeminiFileType.webp, // ✅ Type-safe enum!
      fileName: 'custom.webp',
    );

    print('   ✅ Created: $customFile');
    print('   🏷️ MIME: ${customFile.mimeType}');
    print('   📂 Category: ${customFile.category.displayName}');
    print('');

    // Example 4: File type utilities
    print('🔍 4. File type utilities:');
    print(
        '   📸 All image types: ${GeminiFileType.imageTypes.map((t) => t.name).join(", ")}');
    print(
        '   🎵 All audio types: ${GeminiFileType.audioTypes.map((t) => t.name).join(", ")}');
    print(
        '   🎬 All video types: ${GeminiFileType.videoTypes.map((t) => t.name).join(", ")}');
    print('');

    // Example 5: File collections
    print('📚 5. Working with file collections:');
    final files = <GeminiFile>[customFile];
    if (await catFile.exists()) {
      final imageFile = await GeminiFile.fromFile(catFile);
      files.add(imageFile);
    }
    print('   📊 Total files: ${files.length}');
    print('   💾 Total size: ${files.formattedTotalSize}');
    print('   🖼️ Images: ${files.images.length}');
    print('   📄 Documents: ${files.documents.length}');
    print('');

    client.dispose();

    print('🎉 === BENEFITS OF MAIN EXPORT ===');
    print('✅ Single import: package:gemini_dart/gemini_dart.dart');
    print('✅ No internal path imports needed');
    print('✅ All file types and utilities available');
    print('✅ Clean, readable code');
    print('✅ Type-safe file handling');
    print('✅ Direct integration with GeminiClient');
  } catch (e) {
    print('❌ Error: $e');
  }
}
