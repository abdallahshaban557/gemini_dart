import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug example to see raw API response
void main() async {
  // Initialize authentication
  final auth = AuthenticationHandler();
  final apiKey = Platform.environment['GEMINI_API_KEY'] ??
      'AIzaSyCHv9s5b52BPHqh4SlAJRQVF7O5C36hVl0';
  auth.setApiKey(apiKey);

  // Create configuration
  const config = GeminiConfig();

  // Create HTTP service
  final httpService = HttpService(auth: auth, config: config);

  try {
    // Make a direct API call to see the response format
    final response = await httpService.post(
      'models/gemini-1.5-flash:generateContent',
      body: {
        'contents': [
          {
            'parts': [
              {'text': 'Hello, world!'}
            ]
          }
        ]
      },
    );

    print('Raw API Response:');
    print(response);
  } catch (e) {
    print('Error: $e');
  } finally {
    httpService.dispose();
  }
}
