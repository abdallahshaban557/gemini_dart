import 'package:test/test.dart';
import 'package:gemini_dart/src/core/auth.dart';
import 'package:gemini_dart/src/core/secure_storage.dart';

void main() {
  group('AuthenticationHandler', () {
    late AuthenticationHandler authHandler;
    late InMemorySecureStorage mockStorage;

    setUp(() {
      mockStorage = InMemorySecureStorage();
      authHandler = AuthenticationHandler(secureStorage: mockStorage);
    });

    group('setApiKey', () {
      test('should set valid API key', () {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        authHandler.setApiKey(apiKey);
        expect(authHandler.apiKey, equals(apiKey));
      });

      test('should throw exception for empty API key', () {
        expect(
          () => authHandler.setApiKey(''),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('validateApiKey', () {
      test('should return true for valid API key', () {
        const validKey = 'AIzaSyDummyKeyForTesting123456789';
        expect(authHandler.validateApiKey(validKey), isTrue);
      });

      test('should return false for empty key', () {
        expect(authHandler.validateApiKey(''), isFalse);
      });

      test('should return false for key not starting with AIza', () {
        expect(authHandler.validateApiKey('InvalidKey123456789'), isFalse);
      });

      test('should return false for too short key', () {
        expect(authHandler.validateApiKey('AIza123'), isFalse);
      });
    });

    group('storeApiKey', () {
      test('should store valid API key', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await authHandler.storeApiKey(apiKey);

        expect(authHandler.apiKey, equals(apiKey));
        final stored = await mockStorage.retrieve('gemini_api_key');
        expect(stored, equals(apiKey));
      });

      test('should throw exception for invalid API key', () async {
        expect(
          () => authHandler.storeApiKey('invalid'),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('retrieveStoredApiKey', () {
      test('should retrieve stored API key', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await mockStorage.store('gemini_api_key', apiKey);

        final retrieved = await authHandler.retrieveStoredApiKey();
        expect(retrieved, equals(apiKey));
        expect(authHandler.apiKey, equals(apiKey));
      });

      test('should return null when no key is stored', () async {
        final retrieved = await authHandler.retrieveStoredApiKey();
        expect(retrieved, isNull);
      });
    });

    group('clearStoredApiKey', () {
      test('should clear stored API key', () async {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        await authHandler.storeApiKey(apiKey);

        await authHandler.clearStoredApiKey();

        expect(authHandler.apiKey, isNull);
        final stored = await mockStorage.retrieve('gemini_api_key');
        expect(stored, isNull);
      });
    });

    group('getAuthHeaders', () {
      test('should return correct headers when authenticated', () {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        authHandler.setApiKey(apiKey);

        final headers = authHandler.getAuthHeaders();
        expect(headers['x-goog-api-key'], equals(apiKey));
        expect(headers['Content-Type'], equals('application/json'));
      });

      test('should throw exception when not authenticated', () {
        expect(
          () => authHandler.getAuthHeaders(),
          throwsA(isA<GeminiAuthException>()),
        );
      });
    });

    group('isAuthenticated', () {
      test('should return true when API key is set', () {
        const apiKey = 'AIzaSyDummyKeyForTesting123456789';
        authHandler.setApiKey(apiKey);
        expect(authHandler.isAuthenticated, isTrue);
      });

      test('should return false when API key is not set', () {
        expect(authHandler.isAuthenticated, isFalse);
      });
    });
  });

  group('GeminiAuthException', () {
    test('should create exception with message', () {
      const exception = GeminiAuthException('Test error');
      expect(exception.message, equals('Test error'));
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('should create exception with all parameters', () {
      const originalError = 'Original error';
      const exception = GeminiAuthException(
        'Test error',
        code: 'AUTH_001',
        originalError: originalError,
      );

      expect(exception.message, equals('Test error'));
      expect(exception.code, equals('AUTH_001'));
      expect(exception.originalError, equals(originalError));
    });

    test('should have proper toString representation', () {
      const exception = GeminiAuthException('Test error');
      expect(exception.toString(), equals('GeminiAuthException: Test error'));
    });
  });
}
