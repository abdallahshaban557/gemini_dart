import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  final client = GeminiClient();
  await client.initialize(apiKey); // Add await for the Future

  final result = await client.generateContent('testing a prompt');

  print(result.text);
}
