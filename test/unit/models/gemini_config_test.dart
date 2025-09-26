import 'package:test/test.dart';
import 'package:gemini_dart/src/models/gemini_config.dart';

void main() {
  group('CacheConfig', () {
    test('should create CacheConfig with default values', () {
      const config = CacheConfig();

      expect(config.enabled, isTrue);
      expect(config.maxSizeBytes, equals(10 * 1024 * 1024));
      expect(config.ttl, equals(Duration(hours: 1)));
      expect(config.storageType, equals(CacheStorageType.memory));
    });

    test('should create CacheConfig with custom values', () {
      const config = CacheConfig(
        enabled: false,
        maxSizeBytes: 5 * 1024 * 1024,
        ttl: Duration(minutes: 30),
        storageType: CacheStorageType.disk,
      );

      expect(config.enabled, isFalse);
      expect(config.maxSizeBytes, equals(5 * 1024 * 1024));
      expect(config.ttl, equals(Duration(minutes: 30)));
      expect(config.storageType, equals(CacheStorageType.disk));
    });

    test('should serialize to JSON correctly', () {
      const config = CacheConfig(
        enabled: false,
        maxSizeBytes: 1024,
        ttl: Duration(seconds: 3600),
        storageType: CacheStorageType.hybrid,
      );

      final json = config.toJson();

      expect(
          json,
          equals({
            'enabled': false,
            'maxSizeBytes': 1024,
            'ttlSeconds': 3600,
            'storageType': 'hybrid',
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'enabled': false,
        'maxSizeBytes': 1024,
        'ttlSeconds': 1800,
        'storageType': 'disk',
      };

      final config = CacheConfig.fromJson(json);

      expect(config.enabled, isFalse);
      expect(config.maxSizeBytes, equals(1024));
      expect(config.ttl, equals(Duration(seconds: 1800)));
      expect(config.storageType, equals(CacheStorageType.disk));
    });

    test('should handle missing fields in JSON with defaults', () {
      final json = <String, dynamic>{};
      final config = CacheConfig.fromJson(json);

      expect(config.enabled, isTrue);
      expect(config.maxSizeBytes, equals(10 * 1024 * 1024));
      expect(config.ttl, equals(Duration(seconds: 3600)));
      expect(config.storageType, equals(CacheStorageType.memory));
    });

    test('should handle unknown storage type with default', () {
      final json = {'storageType': 'unknown'};
      final config = CacheConfig.fromJson(json);

      expect(config.storageType, equals(CacheStorageType.memory));
    });

    test('should create copy with modified values', () {
      const original = CacheConfig(enabled: true, maxSizeBytes: 1024);
      final modified =
          original.copyWith(enabled: false, ttl: Duration(minutes: 15));

      expect(modified.enabled, isFalse);
      expect(modified.maxSizeBytes, equals(1024)); // Unchanged
      expect(modified.ttl, equals(Duration(minutes: 15)));
      expect(
          modified.storageType, equals(CacheStorageType.memory)); // Unchanged
    });

    test('should validate maxSizeBytes', () {
      const validConfig = CacheConfig(maxSizeBytes: 1024);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidConfig = CacheConfig(maxSizeBytes: 0);
      expect(() => invalidConfig.validate(), throwsArgumentError);

      const negativeConfig = CacheConfig(maxSizeBytes: -1);
      expect(() => negativeConfig.validate(), throwsArgumentError);
    });

    test('should validate ttl', () {
      const validConfig = CacheConfig(ttl: Duration(seconds: 1));
      expect(() => validConfig.validate(), returnsNormally);

      const invalidConfig = CacheConfig(ttl: Duration.zero);
      expect(() => invalidConfig.validate(), throwsArgumentError);

      const negativeConfig = CacheConfig(ttl: Duration(seconds: -1));
      expect(() => negativeConfig.validate(), throwsArgumentError);
    });

    test('should implement equality correctly', () {
      const config1 = CacheConfig(enabled: true, maxSizeBytes: 1024);
      const config2 = CacheConfig(enabled: true, maxSizeBytes: 1024);
      const config3 = CacheConfig(enabled: false, maxSizeBytes: 1024);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should implement toString correctly', () {
      const config = CacheConfig(enabled: true, maxSizeBytes: 1024);
      final string = config.toString();

      expect(string, contains('CacheConfig'));
      expect(string, contains('enabled: true'));
      expect(string, contains('maxSizeBytes: 1024'));
    });
  });

  group('GeminiConfig', () {
    test('should create GeminiConfig with default values', () {
      const config = GeminiConfig();

      expect(
          config.baseUrl, equals('https://generativelanguage.googleapis.com'));
      expect(config.timeout, equals(const Duration(seconds: 30)));
      expect(config.maxRetries, equals(3));
      expect(config.enableLogging, isFalse);
      expect(config.cacheConfig, isNull);
      expect(config.apiVersion, equals(ApiVersion.v1));
    });

    test('should create GeminiConfig with custom values', () {
      const cacheConfig = CacheConfig(enabled: false);
      const config = GeminiConfig(
        baseUrl: 'https://custom.api.com',
        timeout: Duration(seconds: 60),
        maxRetries: 5,
        enableLogging: true,
        cacheConfig: cacheConfig,
        apiVersion: ApiVersion.v1beta,
      );

      expect(config.baseUrl, equals('https://custom.api.com'));
      expect(config.timeout, equals(const Duration(seconds: 60)));
      expect(config.maxRetries, equals(5));
      expect(config.enableLogging, isTrue);
      expect(config.cacheConfig, equals(cacheConfig));
      expect(config.apiVersion, equals(ApiVersion.v1beta));
    });

    test('should serialize to JSON correctly', () {
      const cacheConfig = CacheConfig(enabled: false);
      const config = GeminiConfig(
        baseUrl: 'https://custom.api.com',
        timeout: Duration(seconds: 45),
        maxRetries: 2,
        enableLogging: true,
        cacheConfig: cacheConfig,
        apiVersion: ApiVersion.v1beta,
      );

      final json = config.toJson();

      expect(json['baseUrl'], equals('https://custom.api.com'));
      expect(json['timeoutSeconds'], equals(45));
      expect(json['maxRetries'], equals(2));
      expect(json['enableLogging'], isTrue);
      expect(json['cacheConfig'], isNotNull);
      expect(json['apiVersion'], equals('v1beta'));
    });

    test('should serialize to JSON without cache config when null', () {
      const config = GeminiConfig();
      final json = config.toJson();

      expect(json.containsKey('cacheConfig'), isFalse);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'baseUrl': 'https://custom.api.com',
        'timeoutSeconds': 45,
        'maxRetries': 2,
        'enableLogging': true,
        'cacheConfig': {
          'enabled': false,
          'maxSizeBytes': 1024,
          'ttlSeconds': 1800,
          'storageType': 'memory',
        },
        'apiVersion': 'v1beta',
      };

      final config = GeminiConfig.fromJson(json);

      expect(config.baseUrl, equals('https://custom.api.com'));
      expect(config.timeout, equals(const Duration(seconds: 45)));
      expect(config.maxRetries, equals(2));
      expect(config.enableLogging, isTrue);
      expect(config.cacheConfig, isNotNull);
      expect(config.cacheConfig!.enabled, isFalse);
      expect(config.apiVersion, equals(ApiVersion.v1beta));
    });

    test('should handle missing fields in JSON with defaults', () {
      final json = <String, dynamic>{};
      final config = GeminiConfig.fromJson(json);

      expect(
          config.baseUrl, equals('https://generativelanguage.googleapis.com'));
      expect(config.timeout, equals(const Duration(seconds: 30)));
      expect(config.maxRetries, equals(3));
      expect(config.enableLogging, isFalse);
      expect(config.cacheConfig, isNull);
      expect(config.apiVersion, equals(ApiVersion.v1));
    });

    test('should create copy with modified values', () {
      const original =
          GeminiConfig(baseUrl: 'https://original.com', maxRetries: 3);
      final modified = original.copyWith(
        baseUrl: 'https://modified.com',
        enableLogging: true,
      );

      expect(modified.baseUrl, equals('https://modified.com'));
      expect(modified.maxRetries, equals(3)); // Unchanged
      expect(modified.enableLogging, isTrue);
      expect(modified.timeout, equals(Duration(seconds: 30))); // Unchanged
    });

    test('should validate baseUrl', () {
      const validConfig = GeminiConfig(baseUrl: 'https://api.example.com');
      expect(() => validConfig.validate(), returnsNormally);

      const emptyConfig = GeminiConfig(baseUrl: '');
      expect(() => emptyConfig.validate(), throwsArgumentError);

      const invalidConfig = GeminiConfig(baseUrl: 'not-a-url');
      expect(() => invalidConfig.validate(), throwsArgumentError);
    });

    test('should validate timeout', () {
      const validConfig = GeminiConfig(timeout: Duration(seconds: 1));
      expect(() => validConfig.validate(), returnsNormally);

      const invalidConfig = GeminiConfig(timeout: Duration.zero);
      expect(() => invalidConfig.validate(), throwsArgumentError);

      const negativeConfig = GeminiConfig(timeout: Duration(seconds: -1));
      expect(() => negativeConfig.validate(), throwsArgumentError);
    });

    test('should validate maxRetries', () {
      const validConfig = GeminiConfig(maxRetries: 0);
      expect(() => validConfig.validate(), returnsNormally);

      const validConfig2 = GeminiConfig(maxRetries: 5);
      expect(() => validConfig2.validate(), returnsNormally);

      const invalidConfig = GeminiConfig(maxRetries: -1);
      expect(() => invalidConfig.validate(), throwsArgumentError);
    });

    test('should validate apiVersion', () {
      const validConfig = GeminiConfig(apiVersion: ApiVersion.v1);
      expect(() => validConfig.validate(), returnsNormally);

      const validBetaConfig = GeminiConfig(apiVersion: ApiVersion.v1beta);
      expect(() => validBetaConfig.validate(), returnsNormally);
    });

    test('should validate cache config when present', () {
      const validCacheConfig = CacheConfig(maxSizeBytes: 1024);
      const validConfig = GeminiConfig(cacheConfig: validCacheConfig);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidCacheConfig = CacheConfig(maxSizeBytes: -1);
      const invalidConfig = GeminiConfig(cacheConfig: invalidCacheConfig);
      expect(() => invalidConfig.validate(), throwsArgumentError);
    });

    test('should implement equality correctly', () {
      const config1 = GeminiConfig(baseUrl: 'https://api.com', maxRetries: 3);
      const config2 = GeminiConfig(baseUrl: 'https://api.com', maxRetries: 3);
      const config3 = GeminiConfig(baseUrl: 'https://other.com', maxRetries: 3);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should implement toString correctly', () {
      const config = GeminiConfig(baseUrl: 'https://api.com', maxRetries: 5);
      final string = config.toString();

      expect(string, contains('GeminiConfig'));
      expect(string, contains('baseUrl: https://api.com'));
      expect(string, contains('maxRetries: 5'));
    });
  });

  group('ApiVersion', () {
    test('should have correct enum values', () {
      expect(ApiVersion.values.length, equals(2));
      expect(ApiVersion.values, contains(ApiVersion.v1));
      expect(ApiVersion.values, contains(ApiVersion.v1beta));
    });

    test('should have correct string values', () {
      expect(ApiVersion.v1.value, equals('v1'));
      expect(ApiVersion.v1beta.value, equals('v1beta'));
    });

    test('should convert to string correctly', () {
      expect(ApiVersion.v1.toString(), equals('v1'));
      expect(ApiVersion.v1beta.toString(), equals('v1beta'));
    });
  });

  group('CacheStorageType', () {
    test('should have correct enum values', () {
      expect(CacheStorageType.values.length, equals(3));
      expect(CacheStorageType.values, contains(CacheStorageType.memory));
      expect(CacheStorageType.values, contains(CacheStorageType.disk));
      expect(CacheStorageType.values, contains(CacheStorageType.hybrid));
    });

    test('should have correct names', () {
      expect(CacheStorageType.memory.name, equals('memory'));
      expect(CacheStorageType.disk.name, equals('disk'));
      expect(CacheStorageType.hybrid.name, equals('hybrid'));
    });
  });
}
