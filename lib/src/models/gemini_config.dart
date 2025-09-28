/// Supported API versions for the Gemini API
enum ApiVersion {
  /// Version 1 (stable)
  v1('v1'),

  /// Version 1 beta (preview features)
  v1beta('v1beta');

  const ApiVersion(this.value);

  /// The string value of the API version
  final String value;

  @override
  String toString() => value;
}

/// Configuration for the Gemini client
class GeminiConfig {
  /// Creates a new GeminiConfig
  const GeminiConfig({
    this.baseUrl = 'https://generativelanguage.googleapis.com',
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.enableLogging = false,
    this.cacheConfig,
    this.apiVersion = ApiVersion.v1,
  });

  /// Create GeminiConfig from JSON
  factory GeminiConfig.fromJson(Map<String, dynamic> json) => GeminiConfig(
        baseUrl: json['baseUrl'] as String? ??
            'https://generativelanguage.googleapis.com',
        timeout: Duration(seconds: json['timeoutSeconds'] as int? ?? 30),
        maxRetries: json['maxRetries'] as int? ?? 3,
        enableLogging: json['enableLogging'] as bool? ?? false,
        cacheConfig: json['cacheConfig'] != null
            ? CacheConfig.fromJson(json['cacheConfig'] as Map<String, dynamic>)
            : null,
        apiVersion: ApiVersion.values.firstWhere(
          (version) => version.value == (json['apiVersion'] as String? ?? 'v1'),
          orElse: () => ApiVersion.v1,
        ),
      );

  /// Base URL for the Gemini API
  final String baseUrl;

  /// Request timeout duration
  final Duration timeout;

  /// Maximum number of retry attempts
  final int maxRetries;

  /// Whether to enable logging
  final bool enableLogging;

  /// Cache configuration
  final CacheConfig? cacheConfig;

  /// API version to use
  final ApiVersion apiVersion;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'baseUrl': baseUrl,
        'timeoutSeconds': timeout.inSeconds,
        'maxRetries': maxRetries,
        'enableLogging': enableLogging,
        if (cacheConfig != null) 'cacheConfig': cacheConfig!.toJson(),
        'apiVersion': apiVersion.value,
      };

  /// Create a copy with modified values
  GeminiConfig copyWith({
    String? baseUrl,
    Duration? timeout,
    int? maxRetries,
    bool? enableLogging,
    CacheConfig? cacheConfig,
    ApiVersion? apiVersion,
  }) =>
      GeminiConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        timeout: timeout ?? this.timeout,
        maxRetries: maxRetries ?? this.maxRetries,
        enableLogging: enableLogging ?? this.enableLogging,
        cacheConfig: cacheConfig ?? this.cacheConfig,
        apiVersion: apiVersion ?? this.apiVersion,
      );

  /// Validate the configuration
  void validate() {
    if (baseUrl.isEmpty) {
      throw ArgumentError('Base URL cannot be empty');
    }

    final uri = Uri.tryParse(baseUrl);
    if (uri == null || !uri.isAbsolute) {
      throw ArgumentError('Base URL must be a valid absolute URL');
    }

    if (timeout.inMilliseconds <= 0) {
      throw ArgumentError('Timeout must be positive');
    }

    if (maxRetries < 0) {
      throw ArgumentError('Max retries cannot be negative');
    }

    // API version validation is now handled by the enum type

    cacheConfig?.validate();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is GeminiConfig &&
        other.baseUrl == baseUrl &&
        other.timeout == timeout &&
        other.maxRetries == maxRetries &&
        other.enableLogging == enableLogging &&
        other.cacheConfig == cacheConfig &&
        other.apiVersion == apiVersion;
  }

  @override
  int get hashCode => Object.hash(
        baseUrl,
        timeout,
        maxRetries,
        enableLogging,
        cacheConfig,
        apiVersion,
      );

  @override
  String toString() => 'GeminiConfig('
      'baseUrl: $baseUrl, '
      'timeout: $timeout, '
      'maxRetries: $maxRetries, '
      'enableLogging: $enableLogging, '
      'cacheConfig: $cacheConfig, '
      'apiVersion: ${apiVersion.value})';
}

/// Configuration for response caching
class CacheConfig {
  /// Creates a new CacheConfig
  const CacheConfig({
    this.enabled = true,
    this.maxSizeBytes = 10 * 1024 * 1024, // 10MB default
    this.ttl = const Duration(hours: 1),
    this.storageType = CacheStorageType.memory,
  });

  /// Create CacheConfig from JSON
  factory CacheConfig.fromJson(Map<String, dynamic> json) => CacheConfig(
        enabled: json['enabled'] as bool? ?? true,
        maxSizeBytes: json['maxSizeBytes'] as int? ?? 10 * 1024 * 1024,
        ttl: Duration(seconds: json['ttlSeconds'] as int? ?? 3600),
        storageType: CacheStorageType.values.firstWhere(
          (type) => type.name == (json['storageType'] as String? ?? 'memory'),
          orElse: () => CacheStorageType.memory,
        ),
      );

  /// Whether caching is enabled
  final bool enabled;

  /// Maximum cache size in bytes
  final int maxSizeBytes;

  /// Cache entry time-to-live
  final Duration ttl;

  /// Cache storage type
  final CacheStorageType storageType;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'maxSizeBytes': maxSizeBytes,
        'ttlSeconds': ttl.inSeconds,
        'storageType': storageType.name,
      };

  /// Create a copy with modified values
  CacheConfig copyWith({
    bool? enabled,
    int? maxSizeBytes,
    Duration? ttl,
    CacheStorageType? storageType,
  }) =>
      CacheConfig(
        enabled: enabled ?? this.enabled,
        maxSizeBytes: maxSizeBytes ?? this.maxSizeBytes,
        ttl: ttl ?? this.ttl,
        storageType: storageType ?? this.storageType,
      );

  /// Validate the cache configuration
  void validate() {
    if (maxSizeBytes <= 0) {
      throw ArgumentError('Max cache size must be positive');
    }

    if (ttl.inMilliseconds <= 0) {
      throw ArgumentError('TTL must be positive');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CacheConfig &&
        other.enabled == enabled &&
        other.maxSizeBytes == maxSizeBytes &&
        other.ttl == ttl &&
        other.storageType == storageType;
  }

  @override
  int get hashCode => Object.hash(enabled, maxSizeBytes, ttl, storageType);

  @override
  String toString() => 'CacheConfig('
      'enabled: $enabled, '
      'maxSizeBytes: $maxSizeBytes, '
      'ttl: $ttl, '
      'storageType: $storageType)';
}

/// Types of cache storage
enum CacheStorageType {
  /// In-memory cache (lost on app restart)
  memory,

  /// Persistent disk cache
  disk,

  /// Hybrid memory + disk cache
  hybrid,
}
