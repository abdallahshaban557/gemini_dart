import 'dart:io';
import 'dart:typed_data';

import 'package:gemini_dart/gemini_dart.dart';
import 'package:gemini_dart/src/core/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiClient Integration Tests', () {
    late GeminiClient client;
    late String testApiKey;

    setUpAll(() {
      // Get API key from environment variable for integration tests
      testApiKey = Platform.environment['GEMINI_API_KEY'] ?? 'test-api-key';
    });

    setUp(() {
      client = GeminiClient();
    });

    tearDown(() {
      client.dispose();
    });

    group('Initialization', () {
      test('should initialize successfully with valid API key', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        await client.initialize(apiKey: testApiKey);
        expect(client.isInitialized, isTrue);
      });

      test('should throw exception with empty API key', () async {
        expect(
          () => client.initialize(apiKey: ''),
          throwsA(isA<GeminiAuthException>()),
        );
      });

      test('should throw exception when not initialized', () {
        expect(
          () => client.generateText(prompt: 'test'),
          throwsA(isA<GeminiException>()),
        );
      });

      test('should initialize with custom config', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        const customConfig = GeminiConfig(
          timeout: Duration(seconds: 60),
          enableLogging: true,
        );

        await client.initialize(apiKey: testApiKey, config: customConfig);
        expect(client.isInitialized, isTrue);
        expect(client.config.timeout, equals(const Duration(seconds: 60)));
        expect(client.config.enableLogging, isTrue);
      });
    });

    group('Text Generation', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should generate content from simple text prompt', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        final response = await client.generateText(prompt: 'Hello, world!');

        expect(response, isNotNull);
        expect(response.candidates, isNotEmpty);
        expect(response.text, isNotNull);
        expect(response.text!.isNotEmpty, isTrue);
      });

      test('should generate content with generation config', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        const config = GenerationConfig(
          temperature: 0.5,
          maxOutputTokens: 100,
        );

        final response = await client.generateText(
          prompt: 'Write a short poem',
          config: config,
        );

        expect(response, isNotNull);
        expect(response.candidates, isNotEmpty);
        expect(response.text, isNotNull);
      });

      test('should generate streaming content', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        final stream = client.generateTextStream(prompt: 'Tell me a story');
        final responses = <String>[];

        await for (final response in stream) {
          if (response.text != null) {
            responses.add(response.text!);
          }
        }

        expect(responses, isNotEmpty);
      });

      test('should handle empty prompt gracefully', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        expect(
          () => client.generateText(prompt: ''),
          throwsA(isA<GeminiValidationException>()),
        );
      });
    });

    group('Multi-Modal Content Generation', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should generate content from mixed content types', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        // Create a simple test image (1x1 pixel PNG)
        // Load a real test image from the example directory
        final imageFile = File('example/generated_images/cat.png');
        Uint8List imageData;
        if (await imageFile.exists()) {
          imageData = await imageFile.readAsBytes();
        } else {
          // Fallback: create a minimal valid PNG if the file doesn't exist
          imageData = Uint8List.fromList([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x00, 0x01, 0x5C, 0xC2, 0x5D, 0xB4,
            0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND chunk
            0xAE, 0x42, 0x60, 0x82,
          ]);
        }

        final response = await client.createMultiModalPrompt(
          files: [
            GeminiFile.fromBytesWithMimeType(
                bytes: imageData, mimeType: 'image/png')
          ],
          config: const GenerationConfig(
            temperature: 0.7,
          ),
        );

        expect(response, isNotNull);
        expect(response.candidates, isNotEmpty);
        expect(response.text, isNotNull);
      });
    });

    group('Multi-Modal Prompts', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should create multi-modal prompt with text and images', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        // Load a real test image from the example directory
        final imageFile = File('example/generated_images/cat.png');
        Uint8List imageData;
        if (await imageFile.exists()) {
          imageData = await imageFile.readAsBytes();
        } else {
          // Fallback: create a minimal valid PNG if the file doesn't exist
          imageData = Uint8List.fromList([
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
            0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
            0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
            0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
            0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
            0x00, 0x01, 0x00, 0x01, 0x5C, 0xC2, 0x5D, 0xB4,
            0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND chunk
            0xAE, 0x42, 0x60, 0x82,
          ]);
        }

        final response = await client.createMultiModalPrompt(
          text: 'Analyze these images:',
          files: [
            GeminiFile.fromBytesWithMimeType(
                bytes: imageData, mimeType: 'image/png'),
          ],
        );

        expect(response, isNotNull);
        expect(response.candidates, isNotEmpty);
        expect(response.text, isNotNull);
      });
    });

    group('Conversation Context', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should maintain conversation context', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        final context = client.createConversationContext();

        // First message
        final response1 = await client.generateText(
          prompt: 'My name is Alice',
          context: context,
        );

        expect(response1, isNotNull);
        expect(context.length, equals(2)); // User + Assistant

        // Second message referencing first
        final response2 = await client.generateText(
          prompt: 'What is my name?',
          context: context,
        );

        expect(response2, isNotNull);
        expect(context.length, equals(4)); // 2 more messages
      });

      test('should create new conversation context', () {
        final context = client.createConversationContext();

        expect(context, isNotNull);
        expect(context.isEmpty, isTrue);
        expect(context.length, equals(0));
      });
    });

    group('Configuration Management', () {
      test('should update configuration', () {
        const newConfig = GeminiConfig(
          timeout: Duration(seconds: 45),
          enableLogging: true,
        );

        client.updateConfig(newConfig);

        expect(client.config.timeout, equals(const Duration(seconds: 45)));
        expect(client.config.enableLogging, isTrue);
      });

      test('should validate configuration on update', () {
        const invalidConfig = GeminiConfig(
          baseUrl: '', // Invalid empty URL
        );

        expect(
          () => client.updateConfig(invalidConfig),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Handler Access', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should provide access to text handler', () {
        final textHandler = client.textHandler;
        expect(textHandler, isNotNull);
      });

      test('should provide access to image handler', () {
        final imageHandler = client.imageHandler;
        expect(imageHandler, isNotNull);
      });

      test('should provide access to multi-modal handler', () {
        final multiModalHandler = client.multiModalHandler;
        expect(multiModalHandler, isNotNull);
      });

      test('should throw when accessing handlers before initialization', () {
        final uninitializedClient = GeminiClient();

        expect(
          () => uninitializedClient.textHandler,
          throwsA(isA<GeminiException>()),
        );

        uninitializedClient.dispose();
      });
    });

    group('Models API', () {
      setUp(() async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }
        await client.initialize(apiKey: testApiKey);
      });

      test('should get available models', () async {
        // Skip if no real API key available
        if (testApiKey == 'test-api-key') {
          return;
        }

        final models = await client.getModels();

        expect(models, isNotNull);
        expect(models, isA<List>());
        // Note: The actual models list may be empty in test environment
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Use invalid API key to trigger auth error
        expect(
          () => client.initialize(apiKey: 'invalid-key'),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('Resource Management', () {
      test('should dispose resources properly', () {
        expect(client.isInitialized, isFalse);

        client.dispose();

        expect(client.isInitialized, isFalse);
      });
    });
  });

  group('FileUploadResponse', () {
    test('should create from JSON correctly', () {
      final json = {
        'file': {
          'uri': 'gs://test-bucket/test-file.mp4',
          'mimeType': 'video/mp4',
          'sizeBytes': 1024,
          'displayName': 'test-file.mp4',
        }
      };

      final response = FileUploadResponse.fromJson(json);

      expect(response.fileUri, equals('gs://test-bucket/test-file.mp4'));
      expect(response.mimeType, equals('video/mp4'));
      expect(response.sizeBytes, equals(1024));
      expect(response.fileName, equals('test-file.mp4'));
    });

    test('should handle missing optional fields', () {
      final json = {
        'file': {
          'uri': 'gs://test-bucket/test-file.mp4',
          'mimeType': 'video/mp4',
          'sizeBytes': 1024,
        }
      };

      final response = FileUploadResponse.fromJson(json);

      expect(response.fileUri, equals('gs://test-bucket/test-file.mp4'));
      expect(response.mimeType, equals('video/mp4'));
      expect(response.sizeBytes, equals(1024));
      expect(response.fileName, isNull);
    });

    test('should throw on missing required fields', () {
      final json = {
        'file': {
          'mimeType': 'video/mp4',
          'sizeBytes': 1024,
        }
      };

      expect(
        () => FileUploadResponse.fromJson(json),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should convert to JSON correctly', () {
      const response = FileUploadResponse(
        fileUri: 'gs://test-bucket/test-file.mp4',
        mimeType: 'video/mp4',
        sizeBytes: 1024,
        fileName: 'test-file.mp4',
      );

      final json = response.toJson();

      expect(json['file']['uri'], equals('gs://test-bucket/test-file.mp4'));
      expect(json['file']['mimeType'], equals('video/mp4'));
      expect(json['file']['sizeBytes'], equals(1024));
      expect(json['file']['displayName'], equals('test-file.mp4'));
    });
  });
}
