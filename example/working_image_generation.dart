import 'dart:convert';
import 'dart:io';
import 'package:gemini_dart/gemini_dart.dart';

/// Working example of image generation with Gemini
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  // Key: Use v1beta API version and correct model
  final httpService = HttpService(
    auth: AuthenticationHandler()..setApiKey(apiKey),
    config: const GeminiConfig(apiVersion: ApiVersion.v1beta),
  );

  print('🎨 Generating image with Gemini...\n');

  try {
    final response = await httpService.post(
      'models/gemini-2.5-flash-image-preview:generateContent',
      body: {
        'contents': [
          {
            'parts': [
              {'text': 'Create a beautiful sunset over mountains'}
            ]
          }
        ]
      },
    );

    print('✅ Response received!');

    if (response['candidates'] != null) {
      final candidates = response['candidates'] as List;
      final candidate = candidates[0];
      final content = candidate['content'];
      final parts = content['parts'] as List;

      String? textDescription;
      String? imageData;
      String? mimeType;

      // Extract both text and image from response
      for (final part in parts) {
        if (part.containsKey('text')) {
          textDescription = part['text'] as String;
        }
        if (part.containsKey('inlineData')) {
          final inlineData = part['inlineData'];
          imageData = inlineData['data'] as String;
          mimeType = inlineData['mimeType'] as String;
        }
      }
      if (textDescription != null) {
        print('📝 Description: $textDescription\n');
      }

      if (imageData != null && mimeType != null) {
        await _saveImage(imageData, mimeType, 'sunset_mountains.png');
        print('🎉 Image generation successful!');
      }
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  httpService.dispose();
}

Future<void> _saveImage(
    String base64Data, String mimeType, String filename) async {
  try {
    final bytes = base64Decode(base64Data);

    final dir = Directory('example/generated_images');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('example/generated_images/$filename');
    await file.writeAsBytes(bytes);

    print('💾 Image saved: ${file.path}');
    print('📏 Size: ${_formatSize(bytes.length)}');
    print('🖼️  MIME type: $mimeType');
  } catch (e) {
    print('❌ Failed to save image: $e');
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
