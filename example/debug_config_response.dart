import 'dart:io';
import 'dart:convert';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug response format when using generation config
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
    print('=== Comparing Responses: With vs Without Config ===');

    // Test 1: Without generation config
    print('Test 1: WITHOUT generation config');
    try {
      final response1 = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Say hello'}
              ]
            }
          ]
        },
      );

      print('✅ Without config - Success');
      print('Response structure:');
      print(JsonEncoder.withIndent('  ').convert(response1));
    } catch (e) {
      print('❌ Without config failed: $e');
    }

    print('\n' + '=' * 50 + '\n');

    // Test 2: With generation config
    print('Test 2: WITH generation config');
    try {
      final response2 = await httpService.post(
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

      print('✅ With config - Success');
      print('Response structure:');
      print(JsonEncoder.withIndent('  ').convert(response2));
    } catch (e) {
      print('❌ With config failed: $e');
    }
  } finally {
    httpService.dispose();
  }
}
