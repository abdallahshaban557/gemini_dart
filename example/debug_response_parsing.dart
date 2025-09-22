import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug response parsing specifically
void main() async {
  final auth = AuthenticationHandler();
  final apiKey = Platform.environment['GEMINI_API_KEY'];

  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY environment variable is not set.');
    exit(1);
  }

  auth.setApiKey(apiKey);
  const config = GeminiConfig();
  final httpService = HttpService(auth: auth, config: config);

  try {
    print('=== Testing Response Parsing ===');

    // Get raw response with config
    final rawResponse = await httpService.post(
      'models/gemini-2.5-flash:generateContent',
      body: {
        'contents': [
          {
            'parts': [
              {'text': 'Say hello'}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 100,
        }
      },
    );

    print('✅ Raw API call successful');

    // Now try to parse it with our GeminiResponse.fromJson
    print('Attempting to parse with GeminiResponse.fromJson...');
    try {
      final geminiResponse = GeminiResponse.fromJson(rawResponse);
      print('✅ GeminiResponse parsing successful');
      print('Text: ${geminiResponse.text}');
      print('Candidates: ${geminiResponse.candidates.length}');
    } catch (e, stackTrace) {
      print('❌ GeminiResponse parsing failed: $e');
      print('Stack trace: $stackTrace');

      // Let's debug the candidates parsing specifically
      print('\nDebugging candidates parsing...');
      try {
        final candidatesJson = rawResponse['candidates'] as List<dynamic>?;
        print('Candidates JSON: $candidatesJson');

        if (candidatesJson != null && candidatesJson.isNotEmpty) {
          final firstCandidate = candidatesJson.first as Map<String, dynamic>;
          print('First candidate: $firstCandidate');

          final contentJson =
              firstCandidate['content'] as Map<String, dynamic>?;
          print('Content JSON: $contentJson');

          if (contentJson != null) {
            print('Attempting Content.fromJson...');
            final content = Content.fromJson(contentJson);
            print('✅ Content parsing successful: $content');
          }
        }
      } catch (debugError, debugStackTrace) {
        print('❌ Debug parsing failed: $debugError');
        print('Debug stack trace: $debugStackTrace');
      }
    }
  } finally {
    httpService.dispose();
  }
}
