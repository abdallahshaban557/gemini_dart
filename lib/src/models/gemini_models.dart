/// Actual Gemini model names with IntelliSense support
class GeminiModels {
  // Text-only models
  /// Gemini 1.5 Flash model for fast text generation
  static const String gemini15Flash = 'gemini-1.5-flash';

  /// Gemini 1.5 Pro model for advanced text and multimodal capabilities
  static const String gemini15Pro = 'gemini-1.5-pro';

  /// Gemini 2.5 Flash model for latest text generation
  static const String gemini25Flash = 'gemini-2.5-flash';

  // Image generation models
  /// Gemini 2.5 Flash Image Preview model for generating images
  static const String gemini25FlashImagePreview =
      'gemini-2.5-flash-image-preview';

  /// All available models
  static const List<String> allModels = [
    gemini15Flash,
    gemini15Pro,
    gemini25Flash,
    gemini25FlashImagePreview,
  ];
}

/// Types of models based on their capabilities
enum ModelType {
  /// Models that only generate text
  textOnly,

  /// Models that can generate both text and images
  imageGeneration,

  /// Models that can analyze images, videos, and generate text
  multiModal,
}
