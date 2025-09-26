import 'dart:convert';
import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Simple check for image data in response
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  final clienting =
      GeminiClient(config: const GeminiConfig(apiVersion: ApiVersion.v1));
  await clienting.initialize(apiKey);

  final testing = await clienting.generateText(prompt: 'testing a prompt');

  print('what the heck ${testing.text}');

  final httpService = HttpService(
    auth: AuthenticationHandler()..setApiKey(apiKey),
    config: const GeminiConfig(apiVersion: ApiVersion.v1beta),
  );

  try {
    final response = await httpService.post(
      'models/gemini-2.5-flash-image-preview:generateContent',
      body: {
        'contents': [
          {
            'parts': [
              {
                'text': 'generate a picture of the swiss alps with '
                    'Godzilla in the middle'
              }
            ]
          }
        ]
      },
    );

    print('✅ Response received!');
    print('Response keys: ${response.keys}');

    if (response['candidates'] != null) {
      final candidates = response['candidates'] as List<dynamic>;
      print('Candidates: ${candidates.length}');

      for (var i = 0; i < candidates.length; i++) {
        final candidate = candidates[i] as Map<String, dynamic>;
        print('Candidate $i keys: ${candidate.keys}');

        if (candidate['content'] != null) {
          final content = candidate['content'] as Map<String, dynamic>;
          print('  Content keys: ${content.keys}');

          if (content['parts'] != null) {
            final parts = content['parts'] as List<dynamic>;
            print('  Parts: ${parts.length}');

            for (var j = 0; j < parts.length; j++) {
              final part = parts[j] as Map<String, dynamic>;
              print('    Part $j keys: ${part.keys}');

              if (part.containsKey('inlineData')) {
                print('    🖼️  FOUND IMAGE DATA!');
                final inlineData = part['inlineData'] as Map<String, dynamic>;
                print('    MIME type: ${inlineData['mimeType']}');

                final data = inlineData['data'] as String?;
                if (data != null) {
                  print('    Base64 data length: ${data.length} characters');

                  // Decode and save
                  final bytes = base64Decode(data);
                  await _saveImage(bytes, 'working_swiss_alps.png');

                  print('\n🎉 SUCCESS! Image generation is working!');
                  httpService.dispose();
                  return;
                }
              }

              if (part.containsKey('text')) {
                final text = part['text'] as String;
                final displayText =
                    text.length > 50 ? '${text.substring(0, 50)}...' : text;
                print('    📝 Text: $displayText');
              }
            }
          }
        }
      }
    }
  } on Exception catch (e) {
    print('❌ Error: $e');
  }

  httpService.dispose();
}

Future<void> _saveImage(List<int> imageData, String filename) async {
  try {
    final dir = Directory('example/generated_images');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final file = File('example/generated_images/$filename');
    await file.writeAsBytes(imageData);

    print('💾 Image saved: ${file.path}');
    print('📏 Size: ${_formatSize(imageData.length)}');
  } on Exception catch (e) {
    print('❌ Failed to save image: $e');
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
