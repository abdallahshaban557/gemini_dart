import 'dart:io';

/// Base exception class for all Gemini-related errors
abstract class GeminiException implements Exception {
  /// The error message
  final String message;

  /// Optional error code
  final String? code;

  /// Original error that caused this exception
  final dynamic originalError;

  /// Creates a new GeminiException
  const GeminiException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'GeminiException: $message';
}

/// Exception thrown when authentication fails
class GeminiAuthException extends GeminiException {
  /// Creates a new GeminiAuthException
  const GeminiAuthException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'GeminiAuthException: $message';
}

/// Exception thrown when rate limits are exceeded
class GeminiRateLimitException extends GeminiException {
  /// Duration to wait before retrying
  final Duration retryAfter;

  /// Creates a new GeminiRateLimitException
  const GeminiRateLimitException(
    super.message,
    this.retryAfter, {
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'GeminiRateLimitException: $message (retry after: $retryAfter)';
}

/// Exception thrown when input validation fails
class GeminiValidationException extends GeminiException {
  /// Field-specific validation errors
  final Map<String, String> fieldErrors;

  /// Creates a new GeminiValidationException
  const GeminiValidationException(
    super.message,
    this.fieldErrors, {
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'GeminiValidationException: $message (fields: $fieldErrors)';
}

/// Exception thrown when network requests fail
class GeminiNetworkException extends GeminiException {
  /// HTTP status code if available
  final int? statusCode;

  /// Creates a new GeminiNetworkException
  const GeminiNetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'GeminiNetworkException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Exception thrown when API quota is exceeded
class GeminiQuotaException extends GeminiException {
  /// Creates a new GeminiQuotaException
  const GeminiQuotaException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'GeminiQuotaException: $message';
}

/// Exception thrown when request times out
class GeminiTimeoutException extends GeminiException {
  /// The timeout duration that was exceeded
  final Duration timeout;

  /// Creates a new GeminiTimeoutException
  const GeminiTimeoutException(
    super.message,
    this.timeout, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'GeminiTimeoutException: $message (timeout: $timeout)';
}

/// Exception thrown when server returns an error
class GeminiServerException extends GeminiException {
  /// HTTP status code
  final int statusCode;

  /// Creates a new GeminiServerException
  const GeminiServerException(
    super.message,
    this.statusCode, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'GeminiServerException: $message (status: $statusCode)';
}

/// Utility class for converting HTTP errors to Gemini exceptions
class ExceptionMapper {
  /// Maps HTTP exceptions to appropriate Gemini exceptions
  static GeminiException mapHttpException(dynamic error, {int? statusCode}) {
    if (error is SocketException) {
      return GeminiNetworkException(
        'Network connection failed: ${error.message}',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (error is HttpException) {
      return GeminiNetworkException(
        'HTTP error: ${error.message}',
        statusCode: statusCode,
        originalError: error,
      );
    }

    if (error is FormatException) {
      return GeminiValidationException(
        'Invalid response format: ${error.message}',
        {},
        originalError: error,
      );
    }

    // Handle timeout exceptions
    if (error.toString().contains('timeout') ||
        error.toString().contains('TimeoutException')) {
      return const GeminiTimeoutException(
        'Request timed out',
        Duration(seconds: 30),
      );
    }

    return GeminiNetworkException(
      'Unexpected error: ${error.toString()}',
      originalError: error,
    );
  }

  /// Maps HTTP status codes to appropriate exceptions
  static GeminiException mapStatusCode(int statusCode, String message,
      {String? responseBody}) {
    switch (statusCode) {
      case 400:
        return GeminiValidationException(
          message.isEmpty ? 'Bad request' : message,
          {},
          code: statusCode.toString(),
        );
      case 401:
        return GeminiAuthException(
          message.isEmpty ? 'Authentication failed' : message,
          code: statusCode.toString(),
        );
      case 403:
        return GeminiAuthException(
          message.isEmpty ? 'Access forbidden' : message,
          code: statusCode.toString(),
        );
      case 404:
        return GeminiNetworkException(
          message.isEmpty ? 'Resource not found' : message,
          statusCode: statusCode,
          code: statusCode.toString(),
        );
      case 429:
        // Extract retry-after from response if available
        final retryAfter = _extractRetryAfter(responseBody);
        return GeminiRateLimitException(
          message.isEmpty ? 'Rate limit exceeded' : message,
          retryAfter,
          code: statusCode.toString(),
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return GeminiServerException(
          message.isEmpty ? 'Server error' : message,
          statusCode,
          code: statusCode.toString(),
        );
      default:
        if (statusCode >= 400 && statusCode < 500) {
          return GeminiValidationException(
            message.isEmpty ? 'Client error' : message,
            {},
            code: statusCode.toString(),
          );
        } else if (statusCode >= 500) {
          return GeminiServerException(
            message.isEmpty ? 'Server error' : message,
            statusCode,
            code: statusCode.toString(),
          );
        } else {
          return GeminiNetworkException(
            message.isEmpty ? 'HTTP error' : message,
            statusCode: statusCode,
            code: statusCode.toString(),
          );
        }
    }
  }

  /// Extracts retry-after duration from response body or headers
  static Duration _extractRetryAfter(String? responseBody) {
    // Default retry after 60 seconds
    const defaultRetryAfter = Duration(seconds: 60);

    if (responseBody == null) return defaultRetryAfter;

    try {
      // Try to parse JSON response for retry information
      // This is a simplified implementation - in practice, you'd parse the actual response
      final retryMatch =
          RegExp(r'"retry_after["\s]*:\s*(\d+)').firstMatch(responseBody);
      if (retryMatch != null) {
        final seconds = int.tryParse(retryMatch.group(1) ?? '');
        if (seconds != null) {
          return Duration(seconds: seconds);
        }
      }
    } catch (_) {
      // Ignore parsing errors
    }

    return defaultRetryAfter;
  }
}
