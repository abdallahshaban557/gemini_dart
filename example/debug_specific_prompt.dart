import 'dart:io';
import 'dart:convert';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug the specific prompt that's causing issues
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
    print('=== Testing Specific Problematic Prompt ===');

    final tokenLimits = [100, 200, 500, 1000];

    for (final maxTokens in tokenLimits) {
      print('\n--- Testing with maxOutputTokens: $maxTokens ---');

      final response = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Explain quantum computing in simple terms'}
              ]
            }
          ],
          'generationConfig': {'temperature': 0.7, 'maxOutputTokens': maxTokens}
        },
      );

      print('Response structure:');
      final candidates = response['candidates'] as List<dynamic>;
      final candidate = candidates[0] as Map<String, dynamic>;
      final content = candidate['content'] as Map<String, dynamic>;

      print('  finishReason: ${candidate['finishReason']}');
      print('  content keys: ${content.keys.toList()}');
      print('  has parts: ${content.containsKey('parts')}');

      if (content.containsKey('parts')) {
        final parts = content['parts'] as List<dynamic>;
        if (parts.isNotEmpty) {
          final text = parts[0]['text'] as String;
          print('  text length: ${text.length}');
          print(
              '  text preview: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');
        } else {
          print('  parts array is empty');
        }
      } else {
        print('  no parts array');
      }

      final usageMetadata = response['usageMetadata'] as Map<String, dynamic>;
      print('  totalTokenCount: ${usageMetadata['totalTokenCount']}');
      print('  thoughtsTokenCount: ${usageMetadata['thoughtsTokenCount']}');
    }
  } finally {
    httpService.dispose();
  }
}
