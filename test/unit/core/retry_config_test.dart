import 'dart:io';

import 'package:test/test.dart';

import '../../../lib/src/core/exceptions.dart';
import '../../../lib/src/core/retry_config.dart';

void main() {
  group('RetryConfig', () {
    test('should create with default values', () {
      final config = RetryConfig();

      expect(config.maxAttempts, equals(3));
      expect(config.initialDelay, equals(const Duration(seconds: 1)));
      expect(config.backoffMultiplier, equals(2.0));
      expect(config.maxDelay, equals(const Duration(seconds: 30)));
      expect(config.retryableExceptions, isNotEmpty);
      expect(config.retryableStatusCodes, isNotEmpty);
    });

    test('should create no-retry config', () {
      const config = RetryConfig.noRetry();

      expect(config.maxAttempts, equals(1));
      expect(config.initialDelay, equals(Duration.zero));
      expect(config.backoffMultiplier, equals(1.0));
      expect(config.maxDelay, equals(Duration.zero));
      expect(config.retryableExceptions, isEmpty);
      expect(config.retryableStatusCodes, isEmpty);
    });

    test('should create aggressive config', () {
      final config = RetryConfig.aggressive();

      expect(config.maxAttempts, equals(5));
      expect(config.initialDelay, equals(const Duration(milliseconds: 500)));
      expect(config.backoffMultiplier, equals(1.5));
      expect(config.maxDelay, equals(const Duration(seconds: 10)));
    });

    test('should create conservative config', () {
      final config = RetryConfig.conservative();

      expect(config.maxAttempts, equals(2));
      expect(config.initialDelay, equals(const Duration(seconds: 2)));
      expect(config.backoffMultiplier, equals(3.0));
      expect(config.maxDelay, equals(const Duration(minutes: 1)));
    });

    group('calculateDelay', () {
      test('should return zero for attempt 0 or negative', () {
        final config = RetryConfig();

        expect(config.calculateDelay(0), equals(Duration.zero));
        expect(config.calculateDelay(-1), equals(Duration.zero));
      });

      test('should calculate exponential backoff correctly', () {
        final config = RetryConfig(
          initialDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
        );

        expect(config.calculateDelay(1), equals(const Duration(seconds: 1)));
        expect(config.calculateDelay(2), equals(const Duration(seconds: 2)));
        expect(config.calculateDelay(3), equals(const Duration(seconds: 4)));
      });

      test('should cap delay at maxDelay', () {
        final config = RetryConfig(
          initialDelay: Duration(seconds: 10),
          backoffMultiplier: 2.0,
          maxDelay: Duration(seconds: 15),
        );

        expect(config.calculateDelay(1), equals(const Duration(seconds: 10)));
        expect(config.calculateDelay(2),
            equals(const Duration(seconds: 15))); // Capped
        expect(config.calculateDelay(3),
            equals(const Duration(seconds: 15))); // Capped
      });
    });

    group('shouldRetry', () {
      final config = RetryConfig(maxAttempts: 3);

      test('should not retry when max attempts reached', () {
        final exception = const SocketException('Connection failed');
        expect(config.shouldRetry(exception, 3), isFalse);
        expect(config.shouldRetry(exception, 4), isFalse);
      });

      test('should retry for retryable exception types', () {
        final socketException = const SocketException('Connection failed');
        final httpException = const HttpException('HTTP error');
        final networkException = const GeminiNetworkException('Network error');
        final timeoutException =
            const GeminiTimeoutException('Timeout', Duration(seconds: 30));
        final rateLimitException = const GeminiRateLimitException(
            'Rate limited', Duration(seconds: 60));
        final serverException =
            const GeminiServerException('Server error', 500);

        expect(config.shouldRetry(socketException, 1), isTrue);
        expect(config.shouldRetry(httpException, 1), isTrue);
        expect(config.shouldRetry(networkException, 1), isTrue);
        expect(config.shouldRetry(timeoutException, 1), isTrue);
        expect(config.shouldRetry(rateLimitException, 1), isTrue);
        expect(config.shouldRetry(serverException, 1), isTrue);
      });

      test('should not retry for non-retryable exceptions', () {
        final authException = const GeminiAuthException('Auth failed');
        final validationException =
            const GeminiValidationException('Validation failed', {});

        expect(config.shouldRetry(authException, 1), isFalse);
        expect(config.shouldRetry(validationException, 1), isFalse);
      });

      test('should retry for network exceptions with retryable status codes',
          () {
        final networkException500 =
            const GeminiNetworkException('Error', statusCode: 500);
        final networkException429 =
            const GeminiNetworkException('Error', statusCode: 429);
        final networkException400 =
            const GeminiNetworkException('Error', statusCode: 400);

        expect(config.shouldRetry(networkException500, 1), isTrue);
        expect(config.shouldRetry(networkException429, 1), isTrue);
        expect(config.shouldRetry(networkException400, 1), isFalse);
      });

      test('should retry for server exceptions with retryable status codes',
          () {
        final serverException500 = const GeminiServerException('Error', 500);
        final serverException502 = const GeminiServerException('Error', 502);
        final serverException503 = const GeminiServerException('Error', 503);

        expect(config.shouldRetry(serverException500, 1), isTrue);
        expect(config.shouldRetry(serverException502, 1), isTrue);
        expect(config.shouldRetry(serverException503, 1), isTrue);
      });
    });

    group('getRateLimitDelay', () {
      test('should return exception retry-after duration when within max', () {
        final config = RetryConfig(maxDelay: Duration(minutes: 2));
        const exception =
            GeminiRateLimitException('Rate limited', Duration(seconds: 30));

        expect(config.getRateLimitDelay(exception),
            equals(const Duration(seconds: 30)));
      });

      test('should cap delay at maxDelay', () {
        final config = RetryConfig(maxDelay: Duration(seconds: 30));
        const exception =
            GeminiRateLimitException('Rate limited', Duration(minutes: 2));

        expect(config.getRateLimitDelay(exception),
            equals(const Duration(seconds: 30)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified values', () {
        final original = RetryConfig();
        final copy = original.copyWith(
          maxAttempts: 5,
          initialDelay: const Duration(seconds: 2),
        );

        expect(copy.maxAttempts, equals(5));
        expect(copy.initialDelay, equals(const Duration(seconds: 2)));
        expect(copy.backoffMultiplier, equals(original.backoffMultiplier));
        expect(copy.maxDelay, equals(original.maxDelay));
      });

      test('should keep original values when not specified', () {
        final original = RetryConfig(maxAttempts: 5);
        final copy = original.copyWith();

        expect(copy.maxAttempts, equals(5));
        expect(copy.initialDelay, equals(original.initialDelay));
      });
    });

    group('validate', () {
      test('should pass validation for valid config', () {
        final config = RetryConfig();
        expect(() => config.validate(), returnsNormally);
      });

      test('should throw for maxAttempts less than 1', () {
        final config = RetryConfig(maxAttempts: 0);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('should throw for negative initialDelay', () {
        final config = RetryConfig(initialDelay: Duration(seconds: -1));
        expect(() => config.validate(), throwsArgumentError);
      });

      test('should throw for non-positive backoffMultiplier', () {
        final config = RetryConfig(backoffMultiplier: 0);
        expect(() => config.validate(), throwsArgumentError);
      });

      test('should throw for negative maxDelay', () {
        final config = RetryConfig(maxDelay: Duration(seconds: -1));
        expect(() => config.validate(), throwsArgumentError);
      });

      test('should throw when maxDelay is less than initialDelay', () {
        final config = RetryConfig(
          initialDelay: Duration(seconds: 10),
          maxDelay: Duration(seconds: 5),
        );
        expect(() => config.validate(), throwsArgumentError);
      });
    });

    group('equality and hashCode', () {
      test('should be equal for same values', () {
        final config1 = RetryConfig(maxAttempts: 3);
        final config2 = RetryConfig(maxAttempts: 3);

        expect(config1, equals(config2));
        expect(config1.hashCode, equals(config2.hashCode));
      });

      test('should not be equal for different values', () {
        final config1 = RetryConfig(maxAttempts: 3);
        final config2 = RetryConfig(maxAttempts: 5);

        expect(config1, isNot(equals(config2)));
      });
    });

    test('should have meaningful toString', () {
      final config = RetryConfig();
      final str = config.toString();

      expect(str, contains('RetryConfig'));
      expect(str, contains('maxAttempts'));
      expect(str, contains('initialDelay'));
      expect(str, contains('backoffMultiplier'));
      expect(str, contains('maxDelay'));
    });
  });
}
