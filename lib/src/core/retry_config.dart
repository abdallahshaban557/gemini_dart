import 'platform_imports.dart';
import 'dart:math';

import 'exceptions.dart';

/// Configuration for retry behavior
class RetryConfig {
  static const List<Type> _defaultRetryableExceptions = [
    PlatformSocketException,
    PlatformHttpException,
    GeminiNetworkException,
    GeminiTimeoutException,
    GeminiRateLimitException,
    GeminiServerException,
  ];

  /// Maximum number of retry attempts
  final int maxAttempts;

  /// Initial delay before first retry
  final Duration initialDelay;

  /// Multiplier for exponential backoff
  final double backoffMultiplier;

  /// Maximum delay between retries
  final Duration maxDelay;

  /// List of exception types that should trigger a retry
  final List<Type> retryableExceptions;

  /// List of HTTP status codes that should trigger a retry
  final List<int> retryableStatusCodes;

  /// Creates a new RetryConfig
  RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.retryableExceptions = _defaultRetryableExceptions,
    this.retryableStatusCodes = const [
      408, // Request Timeout
      429, // Too Many Requests
      500, // Internal Server Error
      502, // Bad Gateway
      503, // Service Unavailable
      504, // Gateway Timeout
    ],
  });

  /// Creates a RetryConfig with no retries
  const RetryConfig.noRetry()
      : maxAttempts = 1,
        initialDelay = Duration.zero,
        backoffMultiplier = 1.0,
        maxDelay = Duration.zero,
        retryableExceptions = const [],
        retryableStatusCodes = const [];

  /// Creates a RetryConfig optimized for aggressive retries
  RetryConfig.aggressive()
      : maxAttempts = 5,
        initialDelay = const Duration(milliseconds: 500),
        backoffMultiplier = 1.5,
        maxDelay = const Duration(seconds: 10),
        retryableExceptions = [
          PlatformSocketException,
          PlatformHttpException,
          GeminiNetworkException,
          GeminiTimeoutException,
          GeminiRateLimitException,
          GeminiServerException,
        ],
        retryableStatusCodes = const [
          408,
          429,
          500,
          502,
          503,
          504,
        ];

  /// Creates a RetryConfig optimized for conservative retries
  RetryConfig.conservative()
      : maxAttempts = 2,
        initialDelay = const Duration(seconds: 2),
        backoffMultiplier = 3.0,
        maxDelay = const Duration(minutes: 1),
        retryableExceptions = [
          PlatformSocketException,
          GeminiNetworkException,
          GeminiTimeoutException,
          GeminiServerException,
        ],
        retryableStatusCodes = const [
          500,
          502,
          503,
          504,
        ];

  /// Calculates the delay for a given attempt number
  Duration calculateDelay(int attemptNumber) {
    if (attemptNumber <= 0) return Duration.zero;

    final delay = initialDelay * pow(backoffMultiplier, attemptNumber - 1);
    final delayMs = delay.inMilliseconds.clamp(0, maxDelay.inMilliseconds);
    return Duration(milliseconds: delayMs);
  }

  /// Determines if an exception should trigger a retry
  bool shouldRetry(dynamic exception, int attemptNumber) {
    if (attemptNumber >= maxAttempts) return false;

    // Check status code-specific exceptions first
    if (exception is GeminiNetworkException && exception.statusCode != null) {
      return retryableStatusCodes.contains(exception.statusCode);
    }

    // GeminiNetworkException without status code should be retryable if in the list
    if (exception is GeminiNetworkException && exception.statusCode == null) {
      return retryableExceptions.contains(GeminiNetworkException);
    }

    if (exception is GeminiServerException) {
      return retryableStatusCodes.contains(exception.statusCode);
    }

    if (exception is GeminiRateLimitException) {
      return retryableExceptions.contains(GeminiRateLimitException);
    }

    // Check if it's a retryable exception type (for exceptions without status codes)
    for (final type in retryableExceptions) {
      if (exception.runtimeType == type) return true;
    }

    return false;
  }

  /// Gets the delay for a rate limit exception
  Duration getRateLimitDelay(GeminiRateLimitException exception) {
    // Use the retry-after duration from the exception, but cap it at maxDelay
    final requestedDelay = exception.retryAfter;
    return Duration(
      milliseconds:
          requestedDelay.inMilliseconds.clamp(0, maxDelay.inMilliseconds),
    );
  }

  /// Creates a copy with modified values
  RetryConfig copyWith({
    int? maxAttempts,
    Duration? initialDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    List<Type>? retryableExceptions,
    List<int>? retryableStatusCodes,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? this.maxAttempts,
      initialDelay: initialDelay ?? this.initialDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxDelay: maxDelay ?? this.maxDelay,
      retryableExceptions: retryableExceptions ?? this.retryableExceptions,
      retryableStatusCodes: retryableStatusCodes ?? this.retryableStatusCodes,
    );
  }

  /// Validates the retry configuration
  void validate() {
    if (maxAttempts < 1) {
      throw ArgumentError('maxAttempts must be at least 1');
    }

    if (initialDelay.isNegative) {
      throw ArgumentError('initialDelay cannot be negative');
    }

    if (backoffMultiplier <= 0) {
      throw ArgumentError('backoffMultiplier must be positive');
    }

    if (maxDelay.isNegative) {
      throw ArgumentError('maxDelay cannot be negative');
    }

    if (maxDelay < initialDelay) {
      throw ArgumentError(
          'maxDelay must be greater than or equal to initialDelay');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetryConfig &&
        other.maxAttempts == maxAttempts &&
        other.initialDelay == initialDelay &&
        other.backoffMultiplier == backoffMultiplier &&
        other.maxDelay == maxDelay &&
        _listEquals(other.retryableExceptions, retryableExceptions) &&
        _listEquals(other.retryableStatusCodes, retryableStatusCodes);
  }

  @override
  int get hashCode => Object.hash(
        maxAttempts,
        initialDelay,
        backoffMultiplier,
        maxDelay,
        Object.hashAll(retryableExceptions),
        Object.hashAll(retryableStatusCodes),
      );

  @override
  String toString() => 'RetryConfig('
      'maxAttempts: $maxAttempts, '
      'initialDelay: $initialDelay, '
      'backoffMultiplier: $backoffMultiplier, '
      'maxDelay: $maxDelay, '
      'retryableExceptions: $retryableExceptions, '
      'retryableStatusCodes: $retryableStatusCodes)';

  /// Helper method to compare lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
