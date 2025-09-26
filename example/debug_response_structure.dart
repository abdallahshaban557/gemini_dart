import 'dart:convert';
import 'dart:io';
import 'package:gemini_dart/gemini_dart.dart';

/// Debug the actual response structure from image generation
void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

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
              {'text': 'swiss alps'}
            ]
          }
        ]
      },
    );

    print('🔍 Raw response structure:');
    print('Response keys: ${response.keys}');

    if (response['candidates'] != null) {
      final candidates = response['candidates'] as List;
      print('Candidates: ${candidates.length}');

      for (int i = 0; i < candidates.length; i++) {
        final candidate = candidates[i];
        print('Candidate $i keys: ${candidate.keys}');

        if (candidate['content'] != null) {
          final content = candidate['content'];
          print('  Content keys: ${content.keys}');

          if (content['parts'] != null) {
            final parts = content['parts'] as List;
            print('  Parts: ${parts.length}');

            for (int j = 0; j < parts.length; j++) {
              final part = parts[j];
              print('    Part $j keys: ${part.keys}');

              if (part.containsKey('text')) {
                print('      Text: ${part['text']}');
              }

              if (part.containsKey('inlineData')) {
                final inlineData = part['inlineData'];
                print('      InlineData keys: ${inlineData.keys}');
                print('      MIME type: ${inlineData['mimeType']}');
                final data = inlineData['data'] as String?;
                if (data != null) {
                  print('      Data length: ${data.length} characters');
                }
              }
            }
          }
        }
      }
    }

    // Now test with GeminiResponse.fromJson
    print('\n🧪 Testing GeminiResponse.fromJson...');
    try {
      final geminiResponse = GeminiResponse.fromJson(response);
      print('✅ GeminiResponse created successfully');
      print('Text: ${geminiResponse.text}');
      print('Candidates: ${geminiResponse.candidates.length}');

      for (int i = 0; i < geminiResponse.candidates.length; i++) {
        final candidate = geminiResponse.candidates[i];
        print('Candidate $i content type: ${candidate.content.runtimeType}');
        if (candidate.content is TextContent) {
          final textContent = candidate.content as TextContent;
          print('  Text content: ${textContent.text}');
        }
      }
    } catch (e) {
      print('❌ Failed to create GeminiResponse: $e');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  httpService.dispose();
}
