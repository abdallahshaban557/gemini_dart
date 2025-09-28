import 'dart:io';
import 'package:gemini_dart/gemini_dart.dart';

/// Super simple streaming example
void main() async {
  // Get your API key from environment
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ Please set GEMINI_API_KEY environment variable');
    exit(1);
  }

  try {
    print('🚀 Simple Streaming Example');
    print('==========================\n');

    // Create a client with streaming-capable model
    final client = GeminiClient(
      model:
          GeminiModels.gemini25Flash, // Disable debug logs for cleaner output
    );
    await client.initialize(apiKey: apiKey);

    print('📡 Streaming response:');
    print('─' * 50);

    int index = 0;

    // Stream the response
    await for (final chunk in client.generateTextStream(
      prompt: 'Write a short poem about coding that is about 1000 words',
    )) {
      // Print each chunk as it arrives
      if (chunk.text != null && chunk.text!.isNotEmpty) {
        stdout.write(
            //add new line after 100 words
            '${index++} index: ${chunk.text!} \n'); // Print without newline for continuous text
      }
    }
    print('✅ Streaming complete!');
  } catch (e) {
    print('❌ Error: $e');
  }
}
