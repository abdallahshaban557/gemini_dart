import 'dart:typed_data';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import 'package:gemini_dart/src/core/exceptions.dart';
import 'package:gemini_dart/src/handlers/image_handler.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/generation_config.dart';
import 'package:gemini_dart/src/models/response.dart';
import 'package:gemini_dart/src/services/http_service.dart';

import 'image_handler_test.mocks.dart';

@GenerateMocks([HttpService])
void main() {
  group('ImageHandler', () {
    late MockHttpService mockHttpService;
    late ImageHandler imageHandler;
    late Uint8List validJpegData;
    late Uint8List validPngData;

    setUp(() {
      mockHttpService = MockHttpService();
      imageHandler = ImageHandler(httpService: mockHttpService);

      // Create valid image data
      validJpegData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      validPngData =
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    });

    group('analyzeImage', () {
      test('should analyze image with text prompt successfully', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'This is a test image analysis.'}
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
        final result = await imageHandler.analyzeImage(
          validJpegData,
          'image/jpeg',
          prompt: 'Describe this image',
        );

        // Assert
        expect(result.text, equals('This is a test image analysis.'));
        verify(mockHttpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: anyNamed('body'),
        )).called(1);
      });

      test('should analyze image without text prompt', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Image analysis without prompt.'}
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
        final result = await imageHandler.analyzeImage(
          validJpegData,
          'image/jpeg',
        );

        // Assert
        expect(result.text, equals('Image analysis without prompt.'));
      });

      test('should throw validation exception for invalid image data',
          () async {
        // Arrange
        final invalidData = Uint8List(0);

        // Act & Assert
        expect(
          () => imageHandler.analyzeImage(invalidData, 'image/jpeg'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw validation exception for invalid MIME type', () async {
        // Act & Assert
        expect(
          () => imageHandler.analyzeImage(validJpegData, 'image/tiff'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('analyzeImages', () {
      test('should analyze multiple images successfully', () async {
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
                  {'text': 'Analysis of multiple images.'}
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
        final result = await imageHandler.analyzeImages(
          images,
          prompt: 'Compare these images',
        );

        // Assert
        expect(result.text, equals('Analysis of multiple images.'));
      });

      test('should throw validation exception for empty images list', () async {
        // Act & Assert
        expect(
          () => imageHandler.analyzeImages([]),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should validate all images in the list', () async {
        // Arrange
        final images = [
          (data: validJpegData, mimeType: 'image/jpeg'),
          (data: Uint8List(0), mimeType: 'image/png'), // Invalid
        ];

        // Act & Assert
        expect(
          () => imageHandler.analyzeImages(images),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('generateFromContent', () {
      test('should generate content from mixed content types', () async {
        // Arrange
        final contents = [
          TextContent('Analyze this image:'),
          ImageContent(validJpegData, 'image/jpeg'),
        ];

        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Mixed content analysis.'}
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
        final result = await imageHandler.generateFromContent(contents);

        // Assert
        expect(result.text, equals('Mixed content analysis.'));
      });

      test('should throw validation exception for empty contents', () async {
        // Act & Assert
        expect(
          () => imageHandler.generateFromContent([]),
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
    });

    group('generateFromContentStream', () {
      test('should generate streaming content', () async {
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
                    {'text': 'Streaming '}
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
                    {'text': 'response.'}
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
            in imageHandler.generateFromContentStream(contents)) {
          responses.add(response);
        }

        // Assert
        expect(responses, hasLength(2));
        expect(responses[0].text, equals('Streaming '));
        expect(responses[1].text, equals('response.'));
      });
    });

    group('compareImages', () {
      test('should compare two images successfully', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Image comparison result.'}
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
        final result = await imageHandler.compareImages(
          validJpegData,
          'image/jpeg',
          validPngData,
          'image/png',
        );

        // Assert
        expect(result.text, equals('Image comparison result.'));
      });

      test('should use custom prompt for comparison', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Custom comparison.'}
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
        final result = await imageHandler.compareImages(
          validJpegData,
          'image/jpeg',
          validPngData,
          'image/png',
          prompt: 'Find the differences',
        );

        // Assert
        expect(result.text, equals('Custom comparison.'));
      });
    });

    group('extractTextFromImage', () {
      test('should extract text from image', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Extracted text from image.'}
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
        final result = await imageHandler.extractTextFromImage(
          validJpegData,
          'image/jpeg',
        );

        // Assert
        expect(result.text, equals('Extracted text from image.'));
      });
    });

    group('describeImage', () {
      test('should describe image without focus area', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'General image description.'}
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
        final result = await imageHandler.describeImage(
          validJpegData,
          'image/jpeg',
        );

        // Assert
        expect(result.text, equals('General image description.'));
      });

      test('should describe image with focus area', () async {
        // Arrange
        final mockResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'Focused image description.'}
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
        final result = await imageHandler.describeImage(
          validJpegData,
          'image/jpeg',
          focusArea: 'people in the image',
        );

        // Assert
        expect(result.text, equals('Focused image description.'));
      });
    });

    group('error handling', () {
      test('should handle network errors', () async {
        // Arrange
        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => imageHandler.analyzeImage(validJpegData, 'image/jpeg'),
          throwsA(isA<GeminiNetworkException>()),
        );
      });

      test('should rethrow GeminiExceptions', () async {
        // Arrange
        when(mockHttpService.post(any, body: anyNamed('body')))
            .thenThrow(const GeminiAuthException('Auth failed'));

        // Act & Assert
        expect(
          () => imageHandler.analyzeImage(validJpegData, 'image/jpeg'),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('generation config validation', () {
      test('should validate generation config when provided', () async {
        // Arrange
        const invalidConfig = GenerationConfig(temperature: 2.0); // Invalid

        // Act & Assert
        expect(
          () => imageHandler.analyzeImage(
            validJpegData,
            'image/jpeg',
            config: invalidConfig,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
