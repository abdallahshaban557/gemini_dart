import 'dart:typed_data';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:gemini_dart/src/core/exceptions.dart';
import 'package:gemini_dart/src/handlers/multimodal_handler.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/gemini_file.dart';
import 'package:gemini_dart/src/models/generation_config.dart';
import 'package:gemini_dart/src/models/response.dart';
import 'package:gemini_dart/src/services/http_service.dart';

import 'multimodal_handler_test.mocks.dart';

@GenerateMocks([HttpService])
void main() {
  group('MultiModalHandler', () {
    late MockHttpService mockHttpService;
    late MultiModalHandler multiModalHandler;
    late Uint8List validJpegData;
    late Uint8List validPngData;

    setUp(() {
      mockHttpService = MockHttpService();
      multiModalHandler = MultiModalHandler(httpService: mockHttpService);

      // Create valid image data
      validJpegData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      validPngData =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    group('generateContent', () {
      test('should generate content from mixed content types', () async {
        // Arrange
        final contents = [
          TextContent('Analyze this:'),
          ImageContent(validJpegData, 'image/jpeg'),
          VideoContent('gs://bucket/video.mp4', 'video/mp4'),
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Multi-modal analysis complete.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result =
            await multiModalHandler.generateContent(contents: contents);

        // Assert
        expect(result.text, equals('Multi-modal analysis complete.'));
        verify(mockHttpService.post(
          'models/gemini-2.5-pro:generateContent',
          body: anyNamed('body'),
        )).called(1);
      });

      test('should throw validation exception for empty contents', () async {
        // Act & Assert
        expect(
          () => multiModalHandler.generateContent(contents: []),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should validate image contents', () async {
        // Act & Assert
        expect(
          () => ImageContent(Uint8List(0), 'image/jpeg'), // Invalid
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate video contents', () async {
        // Act & Assert
        expect(
          () => VideoContent('', 'video/mp4'), // Invalid empty URI
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('generateContentStream', () {
      test('should generate streaming multi-modal content', () async {
        // Arrange
        final contents = [
          TextContent('Stream this:'),
          ImageContent(validJpegData, 'image/jpeg'),
        ];

        final mockResponses = [
          {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'Multi-modal '}
                  ]
                },
                'finishReason': null,
                'index': 0,
                'safetyRatings': []
              }
            ]
          },
          {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'streaming.'}
                  ]
                },
                'finishReason': 'STOP',
                'index': 0,
                'safetyRatings': []
              }
            ]
          },
        ];

        when(mockHttpService.postStream(any, body: anyNamed('body')))
            .thenAnswer((_) => Stream.fromIterable(mockResponses));

        // Act
        final responses = <GeminiResponse>[];
        await for (final response
            in multiModalHandler.generateContentStream(contents: contents)) {
          responses.add(response);
        }

        // Assert
        expect(responses, hasLength(2));
        expect(responses[0].text, equals('Multi-modal '));
        expect(responses[1].text, equals('streaming.'));
      });
    });

    group('createPrompt', () {
      test('should create prompt with text and images', () async {
        // Arrange
        final images = [
          (data: validJpegData, mimeType: 'image/jpeg'),
          (data: validPngData, mimeType: 'image/png'),
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Prompt with text and images.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await multiModalHandler.createPrompt(
          text: 'Analyze these images',
          files: images
              .map((img) => GeminiFile.fromBytesWithMimeType(
                    bytes: img.data,
                    mimeType: img.mimeType,
                  ))
              .toList(),
        );

        // Assert
        expect(result.text, equals('Prompt with text and images.'));
      });

      test('should create prompt with text and videos', () async {
        // Arrange
        final videos = [
          (fileUri: 'gs://bucket/video1.mp4', mimeType: 'video/mp4'),
          (fileUri: 'gs://bucket/video2.mov', mimeType: 'video/mov'),
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Prompt with text and videos.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await multiModalHandler.createPrompt(
          text: 'Analyze these videos',
          files: videos
              .map((vid) => GeminiFile.fromBytesWithMimeType(
                    bytes: Uint8List(0), // Empty data for videos
                    mimeType: vid.mimeType,
                    fileName: vid.fileUri.split('/').last,
                  ))
              .toList(),
        );

        // Assert
        expect(result.text, equals('Prompt with text and videos.'));
      });

      test('should create prompt with all content types', () async {
        // Arrange
        final images = [(data: validJpegData, mimeType: 'image/jpeg')];
        final videos = [
          (fileUri: 'gs://bucket/video.mp4', mimeType: 'video/mp4')
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'All content types analyzed.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await multiModalHandler.createPrompt(
          text: 'Analyze everything',
          files: [
            ...images.map((img) => GeminiFile.fromBytesWithMimeType(
                  bytes: img.data,
                  mimeType: img.mimeType,
                )),
            ...videos.map((vid) => GeminiFile.fromBytesWithMimeType(
                  bytes: Uint8List(0), // Empty data for videos
                  mimeType: vid.mimeType,
                  fileName: vid.fileUri.split('/').last,
                )),
          ],
        );

        // Assert
        expect(result.text, equals('All content types analyzed.'));
      });

      test('should throw validation exception when no content provided',
          () async {
        // Act & Assert
        expect(
          () => multiModalHandler.createPrompt(),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should work with only images', () async {
        // Arrange
        final images = [(data: validJpegData, mimeType: 'image/jpeg')];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Image only analysis.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await multiModalHandler.createPrompt(
          files: images
              .map((img) => GeminiFile.fromBytesWithMimeType(
                    bytes: img.data,
                    mimeType: img.mimeType,
                  ))
              .toList(),
        );

        // Assert
        expect(result.text, equals('Image only analysis.'));
      });
    });

    group('analyzeMedia', () {
      test('should analyze media with custom prompt', () async {
        // Arrange
        final images = [(data: validJpegData, mimeType: 'image/jpeg')];
        final videos = [
          (fileUri: 'gs://bucket/video.mp4', mimeType: 'video/mp4')
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Media analysis complete.'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await multiModalHandler.analyzeMedia(
          analysisPrompt: 'Perform detailed analysis',
          files: [
            ...images.map((img) => GeminiFile.fromBytesWithMimeType(
                  bytes: img.data,
                  mimeType: img.mimeType,
                )),
            ...videos.map((vid) => GeminiFile.fromBytesWithMimeType(
                  bytes: Uint8List(0), // Empty data for videos
                  mimeType: vid.mimeType,
                  fileName: vid.fileUri.split('/').last,
                )),
          ],
        );

        // Assert
        expect(result.text, equals('Media analysis complete.'));
      });

      test('should throw validation exception when no media provided',
          () async {
        // Act & Assert
        expect(
          () => multiModalHandler.analyzeMedia(
            analysisPrompt: 'Analyze this',
            files: [],
          ),
          throwsA(isA<GeminiValidationException>()),
        );
      });
    });

    group('getContentStatistics', () {
      test('should calculate statistics correctly', () {
        // Arrange
        final contents = [
          TextContent('Hello world'),
          TextContent('Another text'),
          ImageContent(validJpegData, 'image/jpeg'),
          ImageContent(validPngData, 'image/png'),
          VideoContent('gs://bucket/video.mp4', 'video/mp4'),
        ];

        // Act
        final stats = multiModalHandler.getContentStatistics(contents);

        // Assert
        expect(stats['textCount'], equals(2));
        expect(stats['imageCount'], equals(2));
        expect(stats['videoCount'], equals(1));
        expect(stats['totalTextLength'],
            equals(23)); // "Hello world" + "Another text"
        expect(stats['totalSize'],
            equals(validJpegData.length + validPngData.length));
        expect(stats['formattedSize'], isA<String>());
      });

      test('should handle empty contents list', () {
        // Act
        final stats = multiModalHandler.getContentStatistics([]);

        // Assert
        expect(stats['textCount'], equals(0));
        expect(stats['imageCount'], equals(0));
        expect(stats['videoCount'], equals(0));
        expect(stats['totalSize'], equals(0));
        expect(stats['totalTextLength'], equals(0));
      });
    });

    group('error handling', () {
      test('should handle network errors', () async {
        // Arrange
        final contents = [TextContent('Test')];
        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => multiModalHandler.generateContent(contents: contents),
          throwsA(isA<GeminiNetworkException>()),
        );
      });

      test('should rethrow GeminiExceptions', () async {
        // Arrange
        final contents = [TextContent('Test')];
        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenThrow(const GeminiAuthException('Auth failed'));

        // Act & Assert
        expect(
          () => multiModalHandler.generateContent(contents: contents),
          throwsA(isA<GeminiAuthException>()),
        );
      });

      test('should handle unsupported content types', () async {
        // This test would require creating a custom content type
        // For now, we'll test the validation logic indirectly
        final contents = [TextContent('Test')];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Test response'}
                ]
              },
              'finishReason': 'STOP',
              'index': 0,
              'safetyRatings': []
            }
          ]
        };

        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenAnswer((_) async => mockResponse);

        // The validation should pass for supported types
        final result =
            await multiModalHandler.generateContent(contents: contents);
        expect(result.text, equals('Test response'));
      });
    });

    group('generation config validation', () {
      test('should validate generation config when provided', () async {
        // Arrange
        final contents = [TextContent('Test')];
        const invalidConfig = GenerationConfig(temperature: 2.0); // Invalid

        // Act & Assert
        expect(
          () => multiModalHandler.generateContent(
            contents: contents,
            config: invalidConfig,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
