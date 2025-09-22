import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug the second API call that's failing
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

  // Create text handler
  final textHandler = TextHandler(httpService: httpService);

  try {
    print('Testing second call with generation config...');

    // Text generation with custom configuration
    const generationConfig = GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 100,
    );

    final response = await textHandler.generateContent(
      'Explain quantum computing in simple terms',
      config: generationConfig,
    );
    print('Success: ${response.text}');
  } catch (e) {
    print('Error: $e');

    // Let's also try the raw API call to see what's happening
    try {
      print('\nTrying raw API call...');
      final rawResponse = await httpService.post(
        'models/gemini-1.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Explain quantum computing in simple terms'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 100,
          }
        },
      );
      print('Raw response: $rawResponse');
    } catch (rawError) {
      print('Raw API error: $rawError');
    }
  } finally {
    httpService.dispose();
  }
}
