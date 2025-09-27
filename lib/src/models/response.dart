import 'content.dart';

/// Response from Gemini API containing generated content and metadata
class GeminiResponse {
  /// The generated text content (convenience accessor)
  final String? text;

  /// List of candidate responses
  final List<Candidate> candidates;

  /// Feedback about the prompt
  final PromptFeedback? promptFeedback;

  /// Usage metadata for the request
  final UsageMetadata? usageMetadata;

  /// Creates a new GeminiResponse
  const GeminiResponse({
    this.text,
    required this.candidates,
    this.promptFeedback,
    this.usageMetadata,
  });

  /// Create GeminiResponse from JSON
  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    final candidatesJson = json['candidates'] as List<dynamic>?;
    final candidates = candidatesJson
            ?.map((c) => Candidate.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    // Extract text from first candidate if available
    String? text;
    if (candidates.isNotEmpty) {
      final content = candidates.first.content;
      if (content is TextContent) {
        text = content.text;
      } else if (content is MultiPartContent) {
        text = content.text;
      }
    }

    return GeminiResponse(
      text: text,
      candidates: candidates,
      promptFeedback: json['promptFeedback'] != null
          ? PromptFeedback.fromJson(
              json['promptFeedback'] as Map<String, dynamic>)
          : null,
      usageMetadata: json['usageMetadata'] != null
          ? UsageMetadata.fromJson(
              json['usageMetadata'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (text != null) 'text': text,
      'candidates': candidates.map((c) => c.toJson()).toList(),
      if (promptFeedback != null) 'promptFeedback': promptFeedback!.toJson(),
      if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiResponse &&
        other.text == text &&
        _listEquals(other.candidates, candidates) &&
        other.promptFeedback == promptFeedback &&
        other.usageMetadata == usageMetadata;
  }

  @override
  int get hashCode =>
      Object.hash(text, candidates, promptFeedback, usageMetadata);

  /// Get the first generated image if available
  ImageContent? get firstImage {
    if (candidates.isEmpty) return null;
    final content = candidates.first.content;
    if (content is MultiPartContent) {
      return content.firstImage;
    } else if (content is ImageContent) {
      return content;
    }
    return null;
  }

  /// Get all generated images
  List<ImageContent> get images {
    final allImages = <ImageContent>[];
    for (final candidate in candidates) {
      final content = candidate.content;
      if (content is MultiPartContent) {
        allImages.addAll(content.images);
      } else if (content is ImageContent) {
        allImages.add(content);
      }
    }
    return allImages;
  }

  /// Check if this response contains generated images
  bool get hasImages {
    return candidates.any((candidate) {
      final content = candidate.content;
      return content is MultiPartContent || content is ImageContent;
    });
  }

  @override
  String toString() =>
      'GeminiResponse(text: $text, candidates: ${candidates.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A candidate response from Gemini
class Candidate {
  /// The generated content
  final Content content;

  /// Reason why generation finished
  final String? finishReason;

  /// Index of this candidate
  final int index;

  /// Safety ratings for this candidate
  final List<SafetyRating> safetyRatings;

  /// Creates a new Candidate
  const Candidate({
    required this.content,
    this.finishReason,
    required this.index,
    required this.safetyRatings,
  });

  /// Create Candidate from JSON
  factory Candidate.fromJson(Map<String, dynamic> json) {
    final contentJson = json['content'] as Map<String, dynamic>?;
    if (contentJson == null) {
      throw ArgumentError('Content field is required for Candidate');
    }

    final safetyRatingsJson = json['safetyRatings'] as List<dynamic>?;
    final safetyRatings = safetyRatingsJson
            ?.map((s) => SafetyRating.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return Candidate(
      content: Content.fromJson(contentJson),
      finishReason: json['finishReason'] as String?,
      index: json['index'] as int? ?? 0,
      safetyRatings: safetyRatings,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'content': content.toJson(),
      if (finishReason != null) 'finishReason': finishReason,
      'index': index,
      'safetyRatings': safetyRatings.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Candidate &&
        other.content == content &&
        other.finishReason == finishReason &&
        other.index == index &&
        GeminiResponse._listEquals(other.safetyRatings, safetyRatings);
  }

  @override
  int get hashCode => Object.hash(content, finishReason, index, safetyRatings);

  @override
  String toString() => 'Candidate(index: $index, finishReason: $finishReason)';
}

/// Safety rating for content
class SafetyRating {
  /// The safety category
  final String category;

  /// The probability of harm
  final String probability;

  /// Creates a new SafetyRating
  const SafetyRating({
    required this.category,
    required this.probability,
  });

  /// Create SafetyRating from JSON
  factory SafetyRating.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    final probability = json['probability'] as String?;

    if (category == null) {
      throw ArgumentError('Category field is required for SafetyRating');
    }
    if (probability == null) {
      throw ArgumentError('Probability field is required for SafetyRating');
    }

    return SafetyRating(
      category: category,
      probability: probability,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'probability': probability,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SafetyRating &&
        other.category == category &&
        other.probability == probability;
  }

  @override
  int get hashCode => Object.hash(category, probability);

  @override
  String toString() =>
      'SafetyRating(category: $category, probability: $probability)';
}

/// Feedback about the prompt
class PromptFeedback {
  /// Block reason if the prompt was blocked
  final String? blockReason;

  /// Safety ratings for the prompt
  final List<SafetyRating> safetyRatings;

  /// Creates a new PromptFeedback
  const PromptFeedback({
    this.blockReason,
    required this.safetyRatings,
  });

  /// Create PromptFeedback from JSON
  factory PromptFeedback.fromJson(Map<String, dynamic> json) {
    final safetyRatingsJson = json['safetyRatings'] as List<dynamic>?;
    final safetyRatings = safetyRatingsJson
            ?.map((s) => SafetyRating.fromJson(s as Map<String, dynamic>))
            .toList() ??
        [];

    return PromptFeedback(
      blockReason: json['blockReason'] as String?,
      safetyRatings: safetyRatings,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (blockReason != null) 'blockReason': blockReason,
      'safetyRatings': safetyRatings.map((s) => s.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PromptFeedback &&
        other.blockReason == blockReason &&
        GeminiResponse._listEquals(other.safetyRatings, safetyRatings);
  }

  @override
  int get hashCode => Object.hash(blockReason, safetyRatings);

  @override
  String toString() => 'PromptFeedback(blockReason: $blockReason)';
}

/// Usage metadata for API requests
class UsageMetadata {
  /// Number of tokens in the prompt
  final int? promptTokenCount;

  /// Number of tokens in the candidates
  final int? candidatesTokenCount;

  /// Total number of tokens used
  final int? totalTokenCount;

  /// Creates a new UsageMetadata
  const UsageMetadata({
    this.promptTokenCount,
    this.candidatesTokenCount,
    this.totalTokenCount,
  });

  /// Create UsageMetadata from JSON
  factory UsageMetadata.fromJson(Map<String, dynamic> json) {
    return UsageMetadata(
      promptTokenCount: json['promptTokenCount'] as int?,
      candidatesTokenCount: json['candidatesTokenCount'] as int?,
      totalTokenCount: json['totalTokenCount'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      if (promptTokenCount != null) 'promptTokenCount': promptTokenCount,
      if (candidatesTokenCount != null)
        'candidatesTokenCount': candidatesTokenCount,
      if (totalTokenCount != null) 'totalTokenCount': totalTokenCount,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UsageMetadata &&
        other.promptTokenCount == promptTokenCount &&
        other.candidatesTokenCount == candidatesTokenCount &&
        other.totalTokenCount == totalTokenCount;
  }

  @override
  int get hashCode =>
      Object.hash(promptTokenCount, candidatesTokenCount, totalTokenCount);

  @override
  String toString() => 'UsageMetadata(total: $totalTokenCount)';
}
