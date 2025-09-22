import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import 'package:gemini_dart/src/handlers/text_handler.dart';
import 'package:gemini_dart/src/handlers/conversation_context.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/generation_config.dart';
import 'package:gemini_dart/src/models/gemini_config.dart';
import 'package:gemini_dart/src/services/http_service.dart';
import 'package:gemini_dart/src/core/auth.dart';
import 'package:gemini_dart/src/core/exceptions.dart';

void main() {
  group('Text Generation Integration Tests', () {
    late TextHandler textHandler;
    late HttpService httpService;

    // Skip integration tests if no API key is provided
    final apiKey = Platform.environment['GEMINI_API_KEY'];

    setUpAll(() {
      if (apiKey == null) {
        print('Skipping integration tests - GEMINI_API_KEY not set');
        return;
      }

      final auth = AuthenticationHandler();
      auth.setApiKey(apiKey);
      final config = GeminiConfig();
      httpService = HttpService(auth: auth, config: config);
      textHandler = TextHandler(httpService: httpService);
    });

    tearDownAll(() {
      httpService.dispose();
    });

    group('Basic Text Generation', () {
      test('should generate content from simple prompt', () async {
        if (apiKey == null) return;

        // Act
        final response = await textHandler.generateContent(
          'Say hello in a friendly way',
        );

        // Assert
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
        expect(response.candidates, isNotEmpty);
        expect(response.candidates.first.content, isA<TextContent>());
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should generate content with generation config', () async {
        if (apiKey == null) return;

        // Arrange
        const config = GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 50,
        );

        // Act
        final response = await textHandler.generateContent(
          'Write a very short greeting',
          config: config,
        );

        // Assert
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
        expect(response.usageMetadata?.totalTokenCount, lessThanOrEqualTo(60));
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should handle multi-modal content', () async {
        if (apiKey == null) return;

        // Arrange
        final contents = [
          TextContent('Describe this in one word:'),
          TextContent('A beautiful sunset over the ocean'),
        ];

        // Act
        final response = await textHandler.generateFromContent(contents);

        // Assert
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Streaming Text Generation', () {
      test('should generate streaming content', () async {
        if (apiKey == null) return;

        // Arrange
        final responses = <String>[];

        // Act
        await for (final response in textHandler.generateContentStream(
          'Tell me a short story about a robot',
        )) {
          if (response.text != null) {
            responses.add(response.text!);
          }
        }

        // Assert
        expect(responses, isNotEmpty);
        final fullText = responses.join();
        expect(fullText.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 45)));

      test('should handle streaming with generation config', () async {
        if (apiKey == null) return;

        // Arrange
        const config = GenerationConfig(
          temperature: 0.8,
          maxOutputTokens: 100,
        );
        final responses = <String>[];

        // Act
        await for (final response in textHandler.generateContentStream(
          'Write a creative haiku',
          config: config,
        )) {
          if (response.text != null) {
            responses.add(response.text!);
          }
        }

        // Assert
        expect(responses, isNotEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Conversation Context', () {
      test('should maintain conversation context', () async {
        if (apiKey == null) return;

        // Arrange
        final context = ConversationContext();

        // Act - First message
        final response1 = await textHandler.generateWithContext(
          context,
          'My name is Alice. Remember this.',
        );

        // Act - Second message referencing first
        final response2 = await textHandler.generateWithContext(
          context,
          'What is my name?',
        );

        // Assert
        expect(response1.text, isNotNull);
        expect(response2.text, isNotNull);
        expect(response2.text!.toLowerCase(), contains('alice'));
        expect(context.length, equals(4)); // 2 user + 2 model messages
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('should handle streaming with conversation context', () async {
        if (apiKey == null) return;

        // Arrange
        final context = ConversationContext();

        // First establish context
        await textHandler.generateWithContext(
          context,
          'I like pizza. Remember this preference.',
        );

        final responses = <String>[];

        // Act - Stream with context
        await for (final response in textHandler.generateStreamWithContext(
          context,
          'What food do I like?',
        )) {
          if (response.text != null) {
            responses.add(response.text!);
          }
        }

        // Assert
        expect(responses, isNotEmpty);
        final fullResponse = responses.join().toLowerCase();
        expect(fullResponse, contains('pizza'));
        expect(context.length, equals(4)); // 2 user + 2 model messages
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('should enforce conversation history limits', () async {
        if (apiKey == null) return;

        // Arrange
        final context = ConversationContext(maxHistoryLength: 4);

        // Act - Add more messages than the limit
        for (int i = 0; i < 6; i++) {
          await textHandler.generateWithContext(
            context,
            'Message number $i',
          );
        }

        // Assert
        expect(context.length, equals(4));
        // Should contain the last 2 conversations (4 messages total)
        final firstMessage = context.history.first;
        expect((firstMessage.parts.first as TextContent).text,
            contains('Message number 4'));
      }, timeout: const Timeout(Duration(seconds: 90)));
    });

    group('Error Handling', () {
      test('should handle invalid prompts gracefully', () async {
        if (apiKey == null) return;

        // Act & Assert
        expect(
          () => textHandler.generateContent(''),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should handle network errors gracefully', () async {
        if (apiKey == null) return;

        // Arrange - Create handler with invalid config
        final invalidAuth = AuthenticationHandler();
        invalidAuth.setApiKey('invalid-key');
        final invalidConfig = GeminiConfig();
        final invalidHttpService = HttpService(
          auth: invalidAuth,
          config: invalidConfig,
        );
        final invalidHandler = TextHandler(httpService: invalidHttpService);

        // Act & Assert
        expect(
          () => invalidHandler.generateContent('Test prompt'),
          throwsA(isA<GeminiException>()),
        );

        invalidHttpService.dispose();
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should validate generation config', () async {
        if (apiKey == null) return;

        // Arrange
        const invalidConfig =
            GenerationConfig(temperature: 2.0); // Invalid temperature

        // Act & Assert
        expect(
          () => textHandler.generateContent(
            'Test prompt',
            config: invalidConfig,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Performance Tests', () {
      test('should handle concurrent requests', () async {
        if (apiKey == null) return;

        // Arrange
        final futures = <Future<String>>[];

        // Act - Make multiple concurrent requests
        for (int i = 0; i < 3; i++) {
          futures.add(
            textHandler
                .generateContent('Say hello $i')
                .then((r) => r.text ?? ''),
          );
        }

        final results = await Future.wait(futures);

        // Assert
        expect(results, hasLength(3));
        for (final result in results) {
          expect(result.isNotEmpty, isTrue);
        }
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('should handle large prompts', () async {
        if (apiKey == null) return;

        // Arrange
        final largePrompt = 'Please summarize this text: ' +
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit. ' * 100;

        // Act
        final response = await textHandler.generateContent(largePrompt);

        // Assert
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
        expect(response.usageMetadata?.promptTokenCount, greaterThan(100));
      }, timeout: const Timeout(Duration(seconds: 45)));
    });
  });
}
