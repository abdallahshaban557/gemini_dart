/// Configuration for content generation parameters
class GenerationConfig {
  /// Controls randomness in generation (0.0 to 1.0)
  final double? temperature;

  /// Maximum number of tokens to generate
  final int? maxOutputTokens;

  /// Top-p sampling parameter (0.0 to 1.0)
  final double? topP;

  /// Top-k sampling parameter
  final int? topK;

  /// Sequences that will stop generation
  final List<String>? stopSequences;

  /// MIME type for the response format
  final String? responseMimeType;

  /// Creates a new GenerationConfig
  const GenerationConfig({
    this.temperature,
    this.maxOutputTokens,
    this.topP,
    this.topK,
    this.stopSequences,
    this.responseMimeType,
  });

  /// Create GenerationConfig from JSON
  factory GenerationConfig.fromJson(Map<String, dynamic> json) {
    return GenerationConfig(
      temperature: (json['temperature'] as num?)?.toDouble(),
      maxOutputTokens: json['maxOutputTokens'] as int?,
      topP: (json['topP'] as num?)?.toDouble(),
      topK: json['topK'] as int?,
      stopSequences: (json['stopSequences'] as List<dynamic>?)
          ?.map((s) => s.toString())
          .toList(),
      responseMimeType: json['responseMimeType'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (temperature != null) json['temperature'] = temperature;
    if (maxOutputTokens != null) json['maxOutputTokens'] = maxOutputTokens;
    if (topP != null) json['topP'] = topP;
    if (topK != null) json['topK'] = topK;
    if (stopSequences != null) json['stopSequences'] = stopSequences;
    if (responseMimeType != null) json['responseMimeType'] = responseMimeType;

    return json;
  }

  /// Create a copy with modified values
  GenerationConfig copyWith({
    double? temperature,
    int? maxOutputTokens,
    double? topP,
    int? topK,
    List<String>? stopSequences,
    String? responseMimeType,
  }) {
    return GenerationConfig(
      temperature: temperature ?? this.temperature,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      stopSequences: stopSequences ?? this.stopSequences,
      responseMimeType: responseMimeType ?? this.responseMimeType,
    );
  }

  /// Validate the configuration parameters
  void validate() {
    if (temperature != null && (temperature! < 0.0 || temperature! > 1.0)) {
      throw ArgumentError('Temperature must be between 0.0 and 1.0');
    }

    if (maxOutputTokens != null && maxOutputTokens! <= 0) {
      throw ArgumentError('Max output tokens must be positive');
    }

    if (topP != null && (topP! < 0.0 || topP! > 1.0)) {
      throw ArgumentError('TopP must be between 0.0 and 1.0');
    }

    if (topK != null && topK! <= 0) {
      throw ArgumentError('TopK must be positive');
    }

    if (stopSequences != null && stopSequences!.isEmpty) {
      throw ArgumentError('Stop sequences cannot be empty if provided');
    }

    if (responseMimeType != null && responseMimeType!.isEmpty) {
      throw ArgumentError('Response MIME type cannot be empty if provided');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GenerationConfig &&
        other.temperature == temperature &&
        other.maxOutputTokens == maxOutputTokens &&
        other.topP == topP &&
        other.topK == topK &&
        _listEquals(other.stopSequences, stopSequences) &&
        other.responseMimeType == responseMimeType;
  }

  @override
  int get hashCode => Object.hash(
        temperature,
        maxOutputTokens,
        topP,
        topK,
        stopSequences,
        responseMimeType,
      );

  @override
  String toString() => 'GenerationConfig('
      'temperature: $temperature, '
      'maxOutputTokens: $maxOutputTokens, '
      'topP: $topP, '
      'topK: $topK, '
      'stopSequences: $stopSequences, '
      'responseMimeType: $responseMimeType)';

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
