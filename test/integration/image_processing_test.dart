import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:gemini_dart/src/core/auth.dart';
import 'package:gemini_dart/src/handlers/image_handler.dart';
import 'package:gemini_dart/src/handlers/multimodal_handler.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/generation_config.dart';
import 'package:gemini_dart/src/models/gemini_config.dart';
import 'package:gemini_dart/src/services/http_service.dart';

void main() {
  group('Image Processing Integration Tests', () {
    late HttpService httpService;
    late ImageHandler imageHandler;
    late MultiModalHandler multiModalHandler;
    late Uint8List testImageData;

    setUpAll(() async {
      // Skip integration tests if no API key is available
      const apiKey = String.fromEnvironment('GEMINI_API_KEY');
      if (apiKey.isEmpty) {
        print('Skipping integration tests - no API key provided');
        return;
      }

      // Initialize services
      final auth = AuthenticationHandler();
      auth.setApiKey(apiKey);
      const config = GeminiConfig(
        baseUrl: 'https://generativelanguage.googleapis.com',
      );
      httpService = HttpService(
        auth: auth,
        config: config,
      );

      imageHandler = ImageHandler(httpService: httpService);
      multiModalHandler = MultiModalHandler(httpService: httpService);

      // Create a simple test image (1x1 PNG)
      testImageData = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
        0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
        0x49, 0x48, 0x44, 0x52, // IHDR
        0x00, 0x00, 0x00, 0x01, // Width: 1
        0x00, 0x00, 0x00, 0x01, // Height: 1
        0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, etc.
        0x90, 0x77, 0x53, 0xDE, // CRC
        0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
        0x49, 0x44, 0x41, 0x54, // IDAT
        0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
        0x00, // Data
        0x02, 0x00, 0x01, // CRC
        0x00, 0x00, 0x00, 0x00, // IEND chunk length
        0x49, 0x45, 0x4E, 0x44, // IEND
        0xAE, 0x42, 0x60, 0x82, // CRC
      ]);
    });

    group('ImageHandler Integration', () {
      test('should analyze image with prompt', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final response = await imageHandler.analyzeImage(
          testImageData,
          'image/png',
          prompt: 'What do you see in this image?',
          config: const GenerationConfig(
            temperature: 0.1,
            maxOutputTokens: 100,
          ),
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
        expect(response.candidates, isNotEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should describe image without prompt', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final response = await imageHandler.describeImage(
          testImageData,
          'image/png',
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should extract text from image (OCR)', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final response = await imageHandler.extractTextFromImage(
          testImageData,
          'image/png',
        );

        expect(response.text, isNotNull);
        // Note: Our test image is just a 1x1 pixel, so there might not be text
        // But the API should still respond
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should analyze multiple images', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final images = [
          (data: testImageData, mimeType: 'image/png'),
          (data: testImageData, mimeType: 'image/png'),
        ];

        final response = await imageHandler.analyzeImages(
          images,
          prompt: 'Compare these two images',
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should compare two images', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final response = await imageHandler.compareImages(
          testImageData,
          'image/png',
          testImageData,
          'image/png',
          prompt: 'What are the similarities and differences?',
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('MultiModalHandler Integration', () {
      test('should generate content from mixed content types', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final contents = [
          TextContent('Please analyze this image and tell me what you see:'),
          ImageContent(testImageData, 'image/png'),
          TextContent('Provide a detailed description.'),
        ];

        final response = await multiModalHandler.generateContent(contents);

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
        expect(response.candidates, isNotEmpty);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should create prompt with text and images', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final images = [
          (data: testImageData, mimeType: 'image/png'),
        ];

        final response = await multiModalHandler.createPrompt(
          text: 'Analyze this image for any interesting features',
          images: images,
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should analyze media with custom prompt', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final images = [
          (data: testImageData, mimeType: 'image/png'),
        ];

        final response = await multiModalHandler.analyzeMedia(
          analysisPrompt: 'Perform a technical analysis of this image',
          images: images,
        );

        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('should generate streaming multi-modal content', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final contents = [
          TextContent('Stream analysis of this image:'),
          ImageContent(testImageData, 'image/png'),
        ];

        final responses = <String>[];
        await for (final response
            in multiModalHandler.generateContentStream(contents)) {
          if (response.text != null) {
            responses.add(response.text!);
          }
        }

        expect(responses, isNotEmpty);
        final fullResponse = responses.join();
        expect(fullResponse.isNotEmpty, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Content Statistics', () {
      test('should calculate content statistics correctly', () {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final contents = [
          TextContent('First text content'),
          ImageContent(testImageData, 'image/png'),
          TextContent('Second text content'),
        ];

        final stats = multiModalHandler.getContentStatistics(contents);

        expect(stats['textCount'], equals(2));
        expect(stats['imageCount'], equals(1));
        expect(stats['videoCount'], equals(0));
        expect(stats['totalTextLength'], equals(35)); // Length of both texts
        expect(stats['totalSize'], equals(testImageData.length));
        expect(stats['formattedSize'], isA<String>());
      });
    });

    group('Error Handling', () {
      test('should handle invalid image data gracefully', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        final invalidImageData = Uint8List.fromList([0x00, 0x01, 0x02]);

        expect(
          () => imageHandler.analyzeImage(invalidImageData, 'image/jpeg'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle unsupported MIME types', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        expect(
          () => imageHandler.analyzeImage(testImageData, 'image/tiff'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle empty content lists', () async {
        const apiKey = String.fromEnvironment('GEMINI_API_KEY');
        if (apiKey.isEmpty) return;

        expect(
          () => multiModalHandler.generateContent([]),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
