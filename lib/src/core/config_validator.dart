import '../models/gemini_config.dart';

/// Exception thrown when configuration validation fails
class ConfigValidationException implements Exception {
  final String message;
  final Map<String, String> fieldErrors;

  const ConfigValidationException(this.message, this.fieldErrors);

  @override
  String toString() => 'ConfigValidationException: $message';
}

/// Validator for Gemini configuration
class ConfigValidator {
  /// Validates a GeminiConfig instance
  static void validateConfig(GeminiConfig config) {
    final errors = <String, String>{};

    // Validate base URL
    if (config.baseUrl.isEmpty) {
      errors['baseUrl'] = 'Base URL cannot be empty';
    } else {
      final uri = Uri.tryParse(config.baseUrl);
      if (uri == null || !uri.isAbsolute) {
        errors['baseUrl'] = 'Base URL must be a valid absolute URL';
      } else if (!uri.scheme.startsWith('http')) {
        errors['baseUrl'] = 'Base URL must use HTTP or HTTPS protocol';
      }
    }

    // Validate timeout
    if (config.timeout.inMilliseconds <= 0) {
      errors['timeout'] = 'Timeout must be positive';
    } else if (config.timeout.inSeconds > 300) {
      errors['timeout'] = 'Timeout should not exceed 5 minutes';
    }

    // Validate max retries
    if (config.maxRetries < 0) {
      errors['maxRetries'] = 'Max retries cannot be negative';
    } else if (config.maxRetries > 10) {
      errors['maxRetries'] = 'Max retries should not exceed 10';
    }

    // Validate API version
    if (config.apiVersion.isEmpty) {
      errors['apiVersion'] = 'API version cannot be empty';
    } else if (!RegExp(r'^v\d+(\.\d+)*$').hasMatch(config.apiVersion)) {
      errors['apiVersion'] = 'API version must follow format v1, v1.1, etc.';
    }

    // Validate cache config if present
    if (config.cacheConfig != null) {
      try {
        validateCacheConfig(config.cacheConfig!);
      } catch (e) {
        if (e is ConfigValidationException) {
          errors.addAll(e.fieldErrors);
        } else {
          errors['cacheConfig'] = 'Invalid cache configuration: $e';
        }
      }
    }

    if (errors.isNotEmpty) {
      throw ConfigValidationException(
        'Configuration validation failed',
        errors,
      );
    }
  }

  /// Validates a CacheConfig instance
  static void validateCacheConfig(CacheConfig config) {
    final errors = <String, String>{};

    // Validate max size
    if (config.maxSizeBytes <= 0) {
      errors['maxSizeBytes'] = 'Max cache size must be positive';
    } else if (config.maxSizeBytes > 1024 * 1024 * 1024) {
      // 1GB limit
      errors['maxSizeBytes'] = 'Max cache size should not exceed 1GB';
    }

    // Validate TTL
    if (config.ttl.inMilliseconds <= 0) {
      errors['ttl'] = 'TTL must be positive';
    } else if (config.ttl.inDays > 30) {
      errors['ttl'] = 'TTL should not exceed 30 days';
    }

    if (errors.isNotEmpty) {
      throw ConfigValidationException(
        'Cache configuration validation failed',
        errors,
      );
    }
  }

  /// Creates a default configuration with validation
  static GeminiConfig createDefaultConfig() {
    const config = GeminiConfig();
    validateConfig(config);
    return config;
  }

  /// Merges user config with defaults and validates
  static GeminiConfig mergeWithDefaults(GeminiConfig? userConfig) {
    if (userConfig == null) {
      return createDefaultConfig();
    }

    final merged = const GeminiConfig().copyWith(
      baseUrl: userConfig.baseUrl,
      timeout: userConfig.timeout,
      maxRetries: userConfig.maxRetries,
      enableLogging: userConfig.enableLogging,
      cacheConfig: userConfig.cacheConfig,
      apiVersion: userConfig.apiVersion,
    );

    validateConfig(merged);
    return merged;
  }
}
