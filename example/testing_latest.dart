import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  final client = GeminiClient();
  await client.initialize(apiKey);

  try {
    // Using the new generateText method for better clarity
    print('🔄 Generating text...');
    final result = await client.generateText(
      prompt: 'Write a short, friendly greeting',
      config: const GenerationConfig(
        temperature: 0.1,
      ),
    );

    final result1 = await client.generateFromContent([]));

    print('✅ Generated text: ${result.text}');

    // The old generateContent method still works but is deprecated
    // final deprecatedResult = await client.generateContent('test');
  } catch (e) {
    print('❌ Exception: ${e.toString()}');
  } finally {
    client.dispose();
  }
}
