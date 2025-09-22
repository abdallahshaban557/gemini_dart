import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Example demonstrating text content generation functionality
void main() async {
  // Initialize authentication
  final auth = AuthenticationHandler();

  // Get API key from environment variable
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY environment variable is not set.');
    print('Please set it using: export GEMINI_API_KEY="your-api-key-here"');
    exit(1);
  }

  auth.setApiKey(apiKey);

  // Create configuration
  const config = GeminiConfig();

  // Create HTTP service
  final httpService = HttpService(auth: auth, config: config);

  // Create text handler with correct model name
  final textHandler =
      TextHandler(httpService: httpService, model: 'gemini-1.5-flash');

  try {
    print('=== Basic Text Generation ===');

    // Simple text generation
    final response1 = await textHandler.generateContent(
      'Write a short poem about artificial intelligence',
    );
    print('Response: ${response1.text}');
    print('Tokens used: ${response1.usageMetadata?.totalTokenCount}');

    print('\n=== Text Generation with Configuration ===');

    // Text generation with custom configuration
    const generationConfig = GenerationConfig(
      temperature: 0.7,
      maxOutputTokens: 100,
    );

    final response2 = await textHandler.generateContent(
      'Explain quantum computing in simple terms',
      config: generationConfig,
    );
    print('Response: ${response2.text}');

    print('\n=== Conversation Context Example ===');

    // Create conversation context
    final context = ConversationContext(maxHistoryLength: 10);

    // First message
    final response3 = await textHandler.generateWithContext(
      context,
      'My name is Alice and I love programming.',
    );
    print('AI: ${response3.text}');

    // Follow-up message that references the context
    final response4 = await textHandler.generateWithContext(
      context,
      'What is my name and what do I love?',
    );
    print('AI: ${response4.text}');

    print('\nConversation history length: ${context.length}');

    print('\n=== Streaming Text Generation ===');

    print('Streaming response:');
    try {
      await for (final chunk in textHandler.generateContentStream(
        'Tell me a short story about a robot learning to paint',
      )) {
        if (chunk.text != null) {
          print('Chunk: ${chunk.text}');
        }
      }
    } catch (e) {
      print('Streaming not available or not supported: $e');
    }

    print('\n=== Multi-Modal Content ===');

    // Generate content from multiple content parts
    final contents = [
      TextContent('Analyze this text: '),
      TextContent('The future of AI is bright and full of possibilities.'),
      TextContent(' What are the key themes?'),
    ];

    final response5 = await textHandler.generateFromContent(contents);
    print('Analysis: ${response5.text}');
  } catch (e) {
    print('Error: $e');
  } finally {
    // Clean up resources
    httpService.dispose();
  }
}
