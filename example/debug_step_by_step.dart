import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug each step of the main example
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
    print('=== Step 1: Basic Text Generation ===');
    final response1 = await textHandler.generateContent(
      'Write a short poem about artificial intelligence',
    );
    print('✅ Success: ${response1.text?.substring(0, 50)}...');

    print('\n=== Step 2: Text Generation with Configuration ===');
    const generationConfig = GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 100,
    );

    final response2 = await textHandler.generateContent(
      'Explain quantum computing in simple terms',
      config: generationConfig,
    );
    print('✅ Success: ${response2.text?.substring(0, 50)}...');

    print('\n=== Step 3: Conversation Context Example ===');
    final context = ConversationContext(maxHistoryLength: 10);

    final response3 = await textHandler.generateWithContext(
      context,
      'My name is Alice and I love programming.',
    );
    print('✅ Success: ${response3.text?.substring(0, 50)}...');

    final response4 = await textHandler.generateWithContext(
      context,
      'What is my name and what do I love?',
    );
    print('✅ Success: ${response4.text?.substring(0, 50)}...');

    print('\n=== All steps completed successfully! ===');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
  } finally {
    httpService.dispose();
  }
}
