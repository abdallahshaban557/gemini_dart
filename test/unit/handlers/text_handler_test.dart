import 'dart:async';

import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:gemini_dart/src/handlers/text_handler.dart';
import 'package:gemini_dart/src/handlers/conversation_context.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/generation_config.dart';
import 'package:gemini_dart/src/models/response.dart';
import 'package:gemini_dart/src/services/http_service.dart';
import 'package:gemini_dart/src/core/exceptions.dart';

import 'text_handler_test.mocks.dart';

@GenerateMocks([HttpService])
void main() {
  group('TextHandler', () {
    late MockHttpService mockHttpService;
    late TextHandler textHandler;

    setUp(() {
      mockHttpService = MockHttpService();
      textHandler = TextHandler(httpService: mockHttpService);
    });

    group('generateContent', () {
      test('should generate content from text prompt', () async {
        // Arrange
        const prompt = 'Hello, world!';
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Hello! How can I help you today?',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await textHandler.generateContent(prompt: prompt);

        // Assert
        expect(result.text, equals('Hello! How can I help you today?'));
        expect(result.candidates, hasLength(1));
        verify(mockHttpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: argThat(
            isA<Map<String, dynamic>>()
                .having((m) => m['contents'], 'contents', isA<List>()),
            named: 'body',
          ),
        )).called(1);
      });

      test('should throw validation exception for empty prompt', () async {
        // Act & Assert
        expect(
          () => textHandler.generateContent(prompt: ''),
          throwsA(isA<GeminiValidationException>()),
        );
        expect(
          () => textHandler.generateContent(prompt: '   '),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should include generation config in request', () async {
        // Arrange
        const prompt = 'Test prompt';
        const config = GenerationConfig(temperature: 0.7, maxOutputTokens: 100);
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Response',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        await textHandler.generateContent(prompt: prompt, config: config);

        // Assert
        verify(mockHttpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: argThat(
            isA<Map<String, dynamic>>().having(
              (m) => m['generationConfig'],
              'generationConfig',
              isNotNull,
            ),
            named: 'body',
          ),
        )).called(1);
      });

      test('should handle conversation context', () async {
        // Arrange
        const prompt = 'Continue the conversation';
        final context = ConversationContext();
        context.addUserMessage('Hello');
        context.addModelResponse(GeminiResponse(
          text: 'Hi there!',
          candidates: [
            Candidate(
              content: TextContent('Hi there!'),
              index: 0,
              safetyRatings: [],
            )
          ],
        ));

        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Sure, what would you like to talk about?',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await textHandler.generateContent(
          prompt: prompt,
          context: context,
        );

        // Assert
        expect(result.text, equals('Sure, what would you like to talk about?'));
        expect(context.length, equals(4)); // Original 2 + new user + new model
      });
    });

    group('generateFromContent', () {
      test('should generate content from content list', () async {
        // Arrange
        final contents = [TextContent('Test content')];
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Generated response',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result =
            await textHandler.generateFromContent(contents: contents);

        // Assert
        expect(result.text, equals('Generated response'));
        verify(mockHttpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: anyNamed('body'),
        )).called(1);
      });

      test('should throw validation exception for empty contents', () async {
        // Act & Assert
        expect(
          () => textHandler.generateFromContent(contents: []),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should handle HTTP service exceptions', () async {
        // Arrange
        final contents = [TextContent('Test')];
        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => textHandler.generateFromContent(contents: contents),
          throwsA(isA<GeminiNetworkException>()),
        );
      });
    });

    group('generateContentStream', () {
      test('should generate streaming content', () async {
        // Arrange
        const prompt = 'Stream test';
        final streamData = [
          {
            'candidates': [
              {
                'content': {
                  'type': 'text',
                  'text': 'Chunk 1',
                },
                'index': 0,
                'safetyRatings': [],
              }
            ],
          },
          {
            'candidates': [
              {
                'content': {
                  'type': 'text',
                  'text': 'Chunk 2',
                },
                'index': 0,
                'safetyRatings': [],
              }
            ],
          },
        ];

        when(mockHttpService.postStream(
          'models/gemini-2.5-flash:streamGenerateContent',
          body: anyNamed('body'),
        )).thenAnswer((_) => Stream.fromIterable(streamData));

        // Act
        final results = <GeminiResponse>[];
        await for (final response
            in textHandler.generateContentStream(prompt: prompt)) {
          results.add(response);
        }

        // Assert
        expect(results, hasLength(2));
        expect(results[0].text, equals('Chunk 1'));
        expect(results[1].text, equals('Chunk 2'));
      });

      test('should throw validation exception for empty prompt', () async {
        // Act & Assert
        expect(
          () => textHandler.generateContentStream(prompt: '').toList(),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should handle conversation context in streaming', () async {
        // Arrange
        const prompt = 'Stream with context';
        final context = ConversationContext();
        final streamData = [
          {
            'candidates': [
              {
                'content': {
                  'type': 'text',
                  'text': 'Streaming response',
                },
                'index': 0,
                'safetyRatings': [],
              }
            ],
          },
        ];

        when(mockHttpService.postStream(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) => Stream.fromIterable(streamData));

        // Act
        final results = <GeminiResponse>[];
        await for (final response in textHandler.generateContentStream(
          prompt: prompt,
          context: context,
        )) {
          results.add(response);
        }

        // Assert
        expect(results, hasLength(1));
        expect(context.length, equals(2)); // User message + model response
      });
    });

    group('generateWithContext', () {
      test('should generate content with conversation context', () async {
        // Arrange
        final context = ConversationContext();
        const prompt = 'Context test';
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Context response',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        // Act
        final result = await textHandler.generateWithContext(context: context, prompt: prompt);

        // Assert
        expect(result.text, equals('Context response'));
        expect(context.length, equals(2)); // User + model messages
      });
    });

    group('generateStreamWithContext', () {
      test('should generate streaming content with context', () async {
        // Arrange
        final context = ConversationContext();
        const prompt = 'Stream context test';
        final streamData = [
          {
            'candidates': [
              {
                'content': {
                  'type': 'text',
                  'text': 'Stream context response',
                },
                'index': 0,
                'safetyRatings': [],
              }
            ],
          },
        ];

        when(mockHttpService.postStream(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) => Stream.fromIterable(streamData));

        // Act
        final results = <GeminiResponse>[];
        await for (final response in textHandler.generateStreamWithContext(
          context,
          prompt,
        )) {
          results.add(response);
        }

        // Assert
        expect(results, hasLength(1));
        expect(results[0].text, equals('Stream context response'));
        expect(context.length, equals(2));
      });
    });

    group('_buildRequestBody', () {
      test('should build request body without context', () async {
        // This is testing a private method indirectly through public methods
        final contents = [TextContent('Test')];
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Response',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        await textHandler.generateFromContent(contents: contents);

        final captured = verify(mockHttpService.post(
          any,
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['contents'], isA<List>());
        expect(captured['contents'][0]['parts'], isA<List>());
      });

      test('should build request body with context', () async {
        final context = ConversationContext();
        context.addUserMessage('Previous message');

        final contents = [TextContent('Current message')];
        final expectedResponse = {
          'candidates': [
            {
              'content': {
                'type': 'text',
                'text': 'Response',
              },
              'index': 0,
              'safetyRatings': [],
            }
          ],
        };

        when(mockHttpService.post(
          any,
          body: anyNamed('body'),
        )).thenAnswer((_) async => expectedResponse);

        await textHandler.generateFromContent(
            contents: contents, context: context);

        final captured = verify(mockHttpService.post(
          any,
          body: captureAnyNamed('body'),
        )).captured.single as Map<String, dynamic>;

        expect(captured['contents'], isA<List>());
        expect(captured['contents'], hasLength(2)); // Previous + current
      });
    });
  });
}
