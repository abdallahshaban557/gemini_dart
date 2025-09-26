import 'package:test/test.dart';
import 'package:gemini_dart/src/core/config_validator.dart';
import 'package:gemini_dart/src/models/gemini_config.dart';

void main() {
  group('ConfigValidator', () {
    group('validateConfig', () {
      test('should validate default configuration', () {
        const config = GeminiConfig();
        expect(() => ConfigValidator.validateConfig(config), returnsNormally);
      });

      test('should throw exception for empty base URL', () {
        const config = GeminiConfig(baseUrl: '');
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for invalid base URL', () {
        const config = GeminiConfig(baseUrl: 'not-a-url');
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for non-HTTP URL', () {
        const config = GeminiConfig(baseUrl: 'ftp://example.com');
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should accept valid HTTPS URL', () {
        const config = GeminiConfig(baseUrl: 'https://api.example.com');
        expect(() => ConfigValidator.validateConfig(config), returnsNormally);
      });

      test('should throw exception for zero timeout', () {
        const config = GeminiConfig(timeout: Duration.zero);
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for excessive timeout', () {
        const config = GeminiConfig(timeout: Duration(minutes: 10));
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for negative max retries', () {
        const config = GeminiConfig(maxRetries: -1);
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for excessive max retries', () {
        const config = GeminiConfig(maxRetries: 15);
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should accept valid API version enum values', () {
        const configs = [
          GeminiConfig(apiVersion: ApiVersion.v1),
          GeminiConfig(apiVersion: ApiVersion.v1beta),
        ];

        for (final config in configs) {
          expect(() => ConfigValidator.validateConfig(config), returnsNormally);
        }
      });

      test('should validate cache config when present', () {
        const config = GeminiConfig(
          cacheConfig: CacheConfig(maxSizeBytes: -1),
        );
        expect(
          () => ConfigValidator.validateConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });

    group('validateCacheConfig', () {
      test('should validate default cache configuration', () {
        const config = CacheConfig();
        expect(
            () => ConfigValidator.validateCacheConfig(config), returnsNormally);
      });

      test('should throw exception for zero max size', () {
        const config = CacheConfig(maxSizeBytes: 0);
        expect(
          () => ConfigValidator.validateCacheConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for negative max size', () {
        const config = CacheConfig(maxSizeBytes: -1);
        expect(
          () => ConfigValidator.validateCacheConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for excessive max size', () {
        const config = CacheConfig(maxSizeBytes: 2 * 1024 * 1024 * 1024);
        expect(
          () => ConfigValidator.validateCacheConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for zero TTL', () {
        const config = CacheConfig(ttl: Duration.zero);
        expect(
          () => ConfigValidator.validateCacheConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });

      test('should throw exception for excessive TTL', () {
        const config = CacheConfig(ttl: Duration(days: 40));
        expect(
          () => ConfigValidator.validateCacheConfig(config),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });

    group('createDefaultConfig', () {
      test('should create valid default configuration', () {
        final config = ConfigValidator.createDefaultConfig();
        expect(() => ConfigValidator.validateConfig(config), returnsNormally);
        expect(config.baseUrl,
            equals('https://generativelanguage.googleapis.com'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
        expect(config.maxRetries, equals(3));
        expect(config.enableLogging, isFalse);
        expect(config.apiVersion, equals(ApiVersion.v1));
      });
    });

    group('mergeWithDefaults', () {
      test('should return default config when user config is null', () {
        final config = ConfigValidator.mergeWithDefaults(null);
        expect(config.baseUrl,
            equals('https://generativelanguage.googleapis.com'));
        expect(config.timeout, equals(const Duration(seconds: 30)));
      });

      test('should merge user config with defaults', () {
        const userConfig = GeminiConfig(
          timeout: Duration(seconds: 60),
          enableLogging: true,
        );

        final merged = ConfigValidator.mergeWithDefaults(userConfig);
        expect(merged.baseUrl,
            equals('https://generativelanguage.googleapis.com'));
        expect(merged.timeout, equals(const Duration(seconds: 60)));
        expect(merged.enableLogging, isTrue);
      });

      test('should validate merged configuration', () {
        const userConfig = GeminiConfig(baseUrl: '');
        expect(
          () => ConfigValidator.mergeWithDefaults(userConfig),
          throwsA(isA<ConfigValidationException>()),
        );
      });
    });
  });

  group('ConfigValidationException', () {
    test('should create exception with message and field errors', () {
      final fieldErrors = {'field1': 'error1', 'field2': 'error2'};
      final exception = ConfigValidationException('Test error', fieldErrors);

      expect(exception.message, equals('Test error'));
      expect(exception.fieldErrors, equals(fieldErrors));
    });

    test('should have proper toString representation', () {
      final fieldErrors = {'field1': 'error1'};
      final exception = ConfigValidationException('Test error', fieldErrors);
      expect(exception.toString(),
          equals('ConfigValidationException: Test error'));
    });
  });
}
