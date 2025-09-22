import 'dart:io';
import 'dart:convert';

import 'package:gemini_dart/gemini_dart.dart';

/// Check response format differences between models
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
    final models = ['gemini-1.5-flash', 'gemini-2.5-flash'];

    for (final model in models) {
      print('=== Testing $model Response Format ===');

      try {
        final response = await httpService.post(
          'models/$model:generateContent',
          body: {
            'contents': [
              {
                'parts': [
                  {'text': 'Say hello'}
                ]
              }
            ],
            'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 50}
          },
        );

        print('Raw response structure:');
        print(JsonEncoder.withIndent('  ').convert(response));
        print('\n');
      } catch (e) {
        print('❌ $model failed: $e\n');
      }
    }
  } finally {
    httpService.dispose();
  }
}
