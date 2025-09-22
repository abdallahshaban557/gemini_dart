import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug streaming functionality
void main() async {
  // Initialize authentication
  final auth = AuthenticationHandler();
  final apiKey = Platform.environment['GEMINI_API_KEY'] ??
      'your-actual-api-key-here';
  auth.setApiKey(apiKey);

  // Create configuration
  const config = GeminiConfig();

  // Create HTTP service
  final httpService = HttpService(auth: auth, config: config);

  try {
    print('Testing streaming...');

    // Test raw streaming
    await for (final chunk in httpService.postStream(
      'models/gemini-1.5-flash:streamGenerateContent',
      body: {
        'contents': [
          {
            'parts': [
              {'text': 'Write a short story about a robot'}
            ]
          }
        ]
      },
    )) {
      print('Raw chunk: $chunk');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    httpService.dispose();
  }
}
