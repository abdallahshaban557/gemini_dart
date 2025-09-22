import 'dart:io';
import 'dart:convert';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug the specific response that's causing issues
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
    print('=== Getting Problematic Response ===');

    // Use the exact same request that's failing
    final body = {
      'contents': [
        {
          'parts': [
            {'text': 'Explain quantum computing in simple terms'}
          ]
        }
      ],
      'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 100}
    };

    final response = await httpService.post(
      'models/gemini-2.5-flash:generateContent',
      body: body,
    );

    print('Raw response:');
    print(JsonEncoder.withIndent('  ').convert(response));

    // Let's specifically look at the content structure
    print('\n=== Analyzing Content Structure ===');
    final candidates = response['candidates'] as List<dynamic>;
    for (int i = 0; i < candidates.length; i++) {
      final candidate = candidates[i] as Map<String, dynamic>;
      print('Candidate $i:');
      print('  Content: ${candidate['content']}');

      final content = candidate['content'] as Map<String, dynamic>;
      print('  Content keys: ${content.keys.toList()}');
      print('  Content type field: ${content['type']}');
      print('  Content parts: ${content['parts']}');

      if (content['parts'] != null) {
        final parts = content['parts'] as List<dynamic>;
        for (int j = 0; j < parts.length; j++) {
          final part = parts[j] as Map<String, dynamic>;
          print('    Part $j: ${part.keys.toList()}');
          print('    Part $j content: $part');
        }
      }
    }
  } finally {
    httpService.dispose();
  }
}
