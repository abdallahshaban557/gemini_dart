import 'dart:io';

import 'package:test/test.dart';

import '../../../lib/src/core/exceptions.dart';

void main() {
  group('GeminiException', () {
    test('should create base exception with message', () {
      const exception = GeminiAuthException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.code, isNull);
      expect(exception.originalError, isNull);
    });

    test('should create exception with all parameters', () {
      const originalError = 'Original error';
      const exception = GeminiAuthException(
        'Test message',
        code: 'TEST_CODE',
        originalError: originalError,
      );

      expect(exception.message, equals('Test message'));
      expect(exception.code, equals('TEST_CODE'));
      expect(exception.originalError, equals(originalError));
    });
  });

  group('GeminiAuthException', () {
    test('should have correct toString', () {
      const exception = GeminiAuthException('Auth failed');
      expect(exception.toString(), equals('GeminiAuthException: Auth failed'));
    });
  });

  group('GeminiRateLimitException', () {
    test('should include retry duration in toString', () {
      const exception = GeminiRateLimitException(
        'Rate limit exceeded',
        Duration(seconds: 60),
      );
      expect(
        exception.toString(),
        equals(
            'GeminiRateLimitException: Rate limit exceeded (retry after: 0:01:00.000000)'),
      );
    });
  });

  group('GeminiValidationException', () {
    test('should include field errors in toString', () {
      const fieldErrors = {'field1': 'Error 1', 'field2': 'Error 2'};
      const exception = GeminiValidationException(
        'Validation failed',
        fieldErrors,
      );
      expect(
        exception.toString(),
        contains('GeminiValidationException: Validation failed'),
      );
      expect(exception.toString(), contains('field1'));
      expect(exception.toString(), contains('field2'));
    });
  });

  group('GeminiNetworkException', () {
    test('should include status code in toString when provided', () {
      const exception = GeminiNetworkException(
        'Network error',
        statusCode: 500,
      );
      expect(
        exception.toString(),
        equals('GeminiNetworkException: Network error (status: 500)'),
      );
    });

    test('should not include status code when not provided', () {
      const exception = GeminiNetworkException('Network error');
      expect(
        exception.toString(),
        equals('GeminiNetworkException: Network error'),
      );
    });
  });

  group('GeminiTimeoutException', () {
    test('should include timeout duration in toString', () {
      const exception = GeminiTimeoutException(
        'Request timed out',
        Duration(seconds: 30),
      );
      expect(
        exception.toString(),
        equals(
            'GeminiTimeoutException: Request timed out (timeout: 0:00:30.000000)'),
      );
    });
  });

  group('GeminiServerException', () {
    test('should include status code in toString', () {
      const exception = GeminiServerException('Server error', 500);
      expect(
        exception.toString(),
        equals('GeminiServerException: Server error (status: 500)'),
      );
    });
  });

  group('ExceptionMapper', () {
    group('mapHttpException', () {
      test('should map SocketException to GeminiNetworkException', () {
        final socketException = const SocketException('Connection failed');
        final mapped = ExceptionMapper.mapHttpException(socketException);

        expect(mapped, isA<GeminiNetworkException>());
        expect(mapped.message, contains('Network connection failed'));
        expect((mapped as GeminiNetworkException).originalError,
            equals(socketException));
      });

      test('should map HttpException to GeminiNetworkException', () {
        final httpException = const HttpException('HTTP error');
        final mapped = ExceptionMapper.mapHttpException(httpException);

        expect(mapped, isA<GeminiNetworkException>());
        expect(mapped.message, contains('HTTP error'));
        expect((mapped as GeminiNetworkException).originalError,
            equals(httpException));
      });

      test('should map FormatException to GeminiValidationException', () {
        final formatException = const FormatException('Invalid format');
        final mapped = ExceptionMapper.mapHttpException(formatException);

        expect(mapped, isA<GeminiValidationException>());
        expect(mapped.message, contains('Invalid response format'));
        expect((mapped as GeminiValidationException).originalError,
            equals(formatException));
      });

      test('should map timeout errors to GeminiTimeoutException', () {
        final timeoutError = Exception('TimeoutException: Request timed out');
        final mapped = ExceptionMapper.mapHttpException(timeoutError);

        expect(mapped, isA<GeminiTimeoutException>());
        expect(mapped.message, equals('Request timed out'));
      });

      test('should map unknown errors to base GeminiException', () {
        final unknownError = Exception('Unknown error');
        final mapped = ExceptionMapper.mapHttpException(unknownError);

        expect(mapped, isA<GeminiException>());
        expect(mapped.message, contains('Unexpected error'));
        expect(mapped.originalError, equals(unknownError));
      });
    });

    group('mapStatusCode', () {
      test('should map 400 to GeminiValidationException', () {
        final mapped = ExceptionMapper.mapStatusCode(400, 'Bad request');
        expect(mapped, isA<GeminiValidationException>());
        expect(mapped.message, equals('Bad request'));
        expect(mapped.code, equals('400'));
      });

      test('should map 401 to GeminiAuthException', () {
        final mapped = ExceptionMapper.mapStatusCode(401, 'Unauthorized');
        expect(mapped, isA<GeminiAuthException>());
        expect(mapped.message, equals('Unauthorized'));
        expect(mapped.code, equals('401'));
      });

      test('should map 403 to GeminiAuthException', () {
        final mapped = ExceptionMapper.mapStatusCode(403, 'Forbidden');
        expect(mapped, isA<GeminiAuthException>());
        expect(mapped.message, equals('Forbidden'));
        expect(mapped.code, equals('403'));
      });

      test('should map 404 to GeminiNetworkException', () {
        final mapped = ExceptionMapper.mapStatusCode(404, 'Not found');
        expect(mapped, isA<GeminiNetworkException>());
        expect(mapped.message, equals('Not found'));
        expect((mapped as GeminiNetworkException).statusCode, equals(404));
      });

      test('should map 429 to GeminiRateLimitException', () {
        final mapped = ExceptionMapper.mapStatusCode(429, 'Rate limited');
        expect(mapped, isA<GeminiRateLimitException>());
        expect(mapped.message, equals('Rate limited'));
        expect(mapped.code, equals('429'));
      });

      test('should map 500 to GeminiServerException', () {
        final mapped = ExceptionMapper.mapStatusCode(500, 'Server error');
        expect(mapped, isA<GeminiServerException>());
        expect(mapped.message, equals('Server error'));
        expect((mapped as GeminiServerException).statusCode, equals(500));
      });

      test('should map 502 to GeminiServerException', () {
        final mapped = ExceptionMapper.mapStatusCode(502, 'Bad gateway');
        expect(mapped, isA<GeminiServerException>());
        expect((mapped as GeminiServerException).statusCode, equals(502));
      });

      test('should use default messages when empty', () {
        final mapped = ExceptionMapper.mapStatusCode(400, '');
        expect(mapped.message, equals('Bad request'));
      });

      test('should extract retry-after from response body', () {
        const responseBody =
            '{"error": {"message": "Rate limited", "retry_after": 120}}';
        final mapped = ExceptionMapper.mapStatusCode(429, 'Rate limited',
            responseBody: responseBody);

        expect(mapped, isA<GeminiRateLimitException>());
        final rateLimitException = mapped as GeminiRateLimitException;
        expect(rateLimitException.retryAfter,
            equals(const Duration(seconds: 120)));
      });

      test('should use default retry-after when parsing fails', () {
        const responseBody = '{"error": {"message": "Rate limited"}}';
        final mapped = ExceptionMapper.mapStatusCode(429, 'Rate limited',
            responseBody: responseBody);

        expect(mapped, isA<GeminiRateLimitException>());
        final rateLimitException = mapped as GeminiRateLimitException;
        expect(
            rateLimitException.retryAfter, equals(const Duration(seconds: 60)));
      });
    });
  });
}
