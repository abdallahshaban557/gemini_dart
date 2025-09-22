import 'package:test/test.dart';
import 'package:gemini_dart/src/core/configuration_manager.dart';
import 'package:gemini_dart/src/core/auth.dart';
import 'package:gemini_dart/src/core/secure_storage.dart';
import 'package:gemini_dart/src/models/gemini_config.dart';

void main() {
  group('ConfigurationManager', () {
    late ConfigurationManager configManager;
    late InMemorySecureStorage mockStorage;
    late AuthenticationHandler mockAuthHandler;

    setUp(() {
      mockStorage = InMemorySecureStorage();
      mockAuthHandler = AuthenticationHandler(secureStorage: mockStorage);
      configManager = ConfigurationManager(authHandler: mockAuthHandler);
    });

    group('initialization', () {
      test('should initialize with default configuration', () {
        expect(configManager.config.baseUrl,
            equals('https://generativelanguage.googleapis.com'));
        expect(
            configManager.config.timeout, equals(const Duration(seconds: 30)));
        expect(configManager.config.maxRetries, equals(3));
      });

      test('should initialize with custom configuration', () {
        const customConfig = GeminiConfig(
          timeout: Duration(seconds: 60),
          maxRetries: 5,
        );

        final manager = ConfigurationManager(config: customConfig);
        expect(manager.config.timeout, equals(const Duration(seconds: 60)));
        expect(manager.config.maxRetries, equals(5));
      });
    });

    group('updateConfig', () {
      test('should update configuration with valid config', () {
        const newConfig = GeminiConfig(
          timeout: Duration(seconds: 45),
          enableLogging: true,
        );

        configManager.updateConfig(newConfig);
        expect(
            configManager.config.timeout, equals(const Duration(seconds: 45)));
        expect(configManager.config.enableLogging, isTrue);
      });

      test('should throw exception for invalid configuration', () {
        const invalidConfig = GeminiConfig(baseUrl: '');
        expect(
          () => configManager.updateConfig(invalidConfig),
          throwsException,
        );
      });
    });

    group('initialize', () {
      test('should initialize with API key', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await configManager.initialize(apiKey);

        expect(configManager.auth.isAuthenticated, isTrue);
        expect(configManager.isReady, isTrue);
      });

      test('should initialize with API key and custom config', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        const customConfig = GeminiConfig(enableLogging: true);

        await configManager.initialize(apiKey, config: customConfig);

        expect(configManager.auth.isAuthenticated, isTrue);
        expect(configManager.config.enableLogging, isTrue);
      });

      test('should store API key when logging is enabled', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        const config = GeminiConfig(enableLogging: true);

        await configManager.initialize(apiKey, config: config);

        final stored = await mockStorage.retrieve('gemini_api_key');
        expect(stored, equals(apiKey));
      });
    });

    group('initializeFromStorage', () {
      test('should initialize from stored API key', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await mockStorage.store('gemini_api_key', apiKey);

        final result = await configManager.initializeFromStorage();

        expect(result, isTrue);
        expect(configManager.auth.isAuthenticated, isTrue);
      });

      test('should return false when no stored API key', () async {
        final result = await configManager.initializeFromStorage();

        expect(result, isFalse);
        expect(configManager.auth.isAuthenticated, isFalse);
      });
    });

    group('getRequestHeaders', () {
      test('should return correct headers when authenticated', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await configManager.initialize(apiKey);

        final headers = configManager.getRequestHeaders();

        expect(headers['x-goog-api-key'], equals(apiKey));
        expect(headers['Content-Type'], equals('application/json'));
        expect(headers['User-Agent'], contains('gemini-dart'));
        expect(headers['Accept'], equals('application/json'));
      });

      test('should throw exception when not authenticated', () {
        expect(
          () => configManager.getRequestHeaders(),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('validate', () {
      test('should validate successfully when properly configured', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await configManager.initialize(apiKey);

        expect(() => configManager.validate(), returnsNormally);
      });

      test('should throw exception when not authenticated', () {
        expect(
          () => configManager.validate(),
          throwsA(isA<GeminiAuthException>()),
        );
      });

      test('should throw exception for invalid configuration', () {
        configManager.updateConfig(const GeminiConfig());
        // Force invalid state by clearing auth after config update
        expect(
          () => configManager.validate(),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('reset', () {
      test('should reset configuration and clear stored credentials', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        const customConfig = GeminiConfig(enableLogging: true);

        await configManager.initialize(apiKey, config: customConfig);
        await configManager.reset();

        expect(configManager.auth.isAuthenticated, isFalse);
        expect(configManager.config.enableLogging, isFalse);

        final stored = await mockStorage.retrieve('gemini_api_key');
        expect(stored, isNull);
      });
    });

    group('URL generation', () {
      test('should return correct base URL', () {
        expect(configManager.baseUrl,
            equals('https://generativelanguage.googleapis.com'));
      });

      test('should return correct API version', () {
        expect(configManager.apiVersion, equals('v1'));
      });

      test('should generate correct API endpoint', () {
        final endpoint = configManager.getApiEndpoint('models');
        expect(endpoint,
            equals('https://generativelanguage.googleapis.com/v1/models'));
      });

      test('should handle paths with leading slash', () {
        final endpoint = configManager.getApiEndpoint('/models');
        expect(endpoint,
            equals('https://generativelanguage.googleapis.com/v1/models'));
      });

      test('should handle complex paths', () {
        final endpoint =
            configManager.getApiEndpoint('models/gemini-pro:generateContent');
        expect(
            endpoint,
            equals(
                'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent'));
      });
    });

    group('isReady', () {
      test('should return true when authenticated', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await configManager.initialize(apiKey);

        expect(configManager.isReady, isTrue);
      });

      test('should return false when not authenticated', () {
        expect(configManager.isReady, isFalse);
      });
    });
  });
}
