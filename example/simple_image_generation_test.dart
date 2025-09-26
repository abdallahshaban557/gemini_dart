import 'dart:convert';
import 'dart:io';
import 'package:gemini_dart/gemini_dart.dart';

/// Simple test to verify image generation works and extract image data
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  print('🎨 Testing simple image generation...\n');

  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    // Use the working approach directly
    final httpService = HttpService(
      auth: AuthenticationHandler()..setApiKey(apiKey),
      config: const GeminiConfig(apiVersion: ApiVersion.v1beta),
    );

    final response = await httpService.post(
      'models/gemini-2.5-flash-image-preview:generateContent',
      body: {
        'contents': [
          {
            'parts': [
              {'text': 'A beautiful mountain landscape'}
            ]
          }
        ]
      },
    );

    print('✅ Raw response received');

    // Extract text and image manually
    final candidates = response['candidates'] as List;
    final candidate = candidates[0];
    final content = candidate['content'];
    final parts = content['parts'] as List;

    String? textDescription;
    String? imageData;
    String? mimeType;

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
      print('📝 Description: $textDescription');
    }

    if (imageData != null && mimeType != null) {
      final bytes = base64Decode(imageData);
      await _saveImage(bytes, 'simple_test_mountain.png');
      print('🎉 Image generation successful!');
      print('📏 Image size: ${_formatSize(bytes.length)}');
      print('🖼️  MIME type: $mimeType');
    } else {
      print('❌ No image data found');
    }

    httpService.dispose();
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
