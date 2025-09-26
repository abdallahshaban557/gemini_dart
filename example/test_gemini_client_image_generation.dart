import 'dart:convert';
import 'dart:io';
import 'package:gemini_dart/gemini_dart.dart';

/// Test GeminiClient image generation functionality
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  print('🧪 Testing GeminiClient image generation...\n');

  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    print('🎨 Generating image: "A peaceful lake surrounded by trees"');

    final response = await client.generateImage(
        'A peaceful lake surrounded by trees at dawn with mist rising from the water');

    print('✅ Response received!');
    print('📝 Text: ${response.text}');

    // Check if we have image data in the response
    bool foundImage = false;

    for (final candidate in response.candidates) {
      for (final part in candidate.content.parts) {
        if (part is ImagePart) {
          print('🖼️  Found image data!');
          print('📏 Size: ${_formatSize(part.data.length)}');

          // Save the image
          await _saveImage(part.data, 'gemini_client_lake.png');
          foundImage = true;
          break;
        }
      }
      if (foundImage) break;
    }

    if (!foundImage) {
      print('⚠️  No image data found in response');
      print('Response structure:');
      for (int i = 0; i < response.candidates.length; i++) {
        final candidate = response.candidates[i];
        print('Candidate $i:');
        for (int j = 0; j < candidate.content.parts.length; j++) {
          final part = candidate.content.parts[j];
          print('  Part $j: ${part.runtimeType}');
          if (part is TextPart) {
            print('    Text: ${part.text.substring(0, 50)}...');
          }
        }
      }
    } else {
      print('🎉 GeminiClient image generation working perfectly!');
    }
  } catch (e) {
    print('❌ Error: $e');
  } finally {
    client.dispose();
  }
}

Future<void> _saveImage(List<int> imageData, String filename) async {
  try {
    final dir = Directory('example/generated_images');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('example/generated_images/$filename');
    await file.writeAsBytes(imageData);

    print('💾 Image saved: ${file.path}');
  } catch (e) {
    print('❌ Failed to save image: $e');
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
