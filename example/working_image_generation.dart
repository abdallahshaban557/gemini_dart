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
    config: const GeminiConfig(apiVersion: 'v1beta'),
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