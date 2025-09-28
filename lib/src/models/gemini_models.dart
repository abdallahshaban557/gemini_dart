import 'gemini_config.dart';

/// Represents a Gemini model with its configuration
class GeminiModel {
  /// Creates a new GeminiModel
  const GeminiModel({
    required this.name,
    required this.apiVersion,
    required this.type,
    this.description,
  });

  /// The model name (e.g., 'gemini-1.5-flash')
  final String name;

  /// The API version this model requires
  final ApiVersion apiVersion;

  /// The type/capabilities of this model
  final ModelType type;

  /// Optional description of the model
  final String? description;

  @override
  String toString() => name;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiModel && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

/// Actual Gemini model definitions with API versions and capabilities
class GeminiModels {
  // Text-only models (v1 API)
  /// Gemini 1.5 Flash model for fast text generation
  static const GeminiModel gemini15Flash = GeminiModel(
    name: 'gemini-1.5-flash',
    apiVersion: ApiVersion.v1,
    type: ModelType.textOnly,
    description: 'Fast text generation model',
  );

  /// Gemini 1.5 Pro model for advanced text and multimodal capabilities
  static const GeminiModel gemini15Pro = GeminiModel(
    name: 'gemini-1.5-pro',
    apiVersion: ApiVersion.v1,
    type: ModelType.multiModal,
    description: 'Advanced text and multimodal capabilities',
  );

  /// Gemini 2.5 Flash model for latest text generation
  static const GeminiModel gemini25Flash = GeminiModel(
    name: 'gemini-2.5-flash',
    apiVersion: ApiVersion.v1,
    type: ModelType.textOnly,
    description: 'Latest fast text generation model',
  );

  // Image generation models (v1beta API)
  /// Gemini 2.5 Flash Image Preview model for generating images
  static const GeminiModel gemini25FlashImagePreview = GeminiModel(
    name: 'gemini-2.5-flash-image-preview',
    apiVersion: ApiVersion.v1beta,
    type: ModelType.imageGeneration,
    description: 'Image generation model (preview)',
  );

  /// All available models
  static const List<GeminiModel> allModels = [
    gemini15Flash,
    gemini15Pro,
    gemini25Flash,
    gemini25FlashImagePreview,
  ];

  /// Get models by type
  static List<GeminiModel> getModelsByType(ModelType type) {
    return allModels.where((model) => model.type == type).toList();
  }

  /// Get models by API version
  static List<GeminiModel> getModelsByApiVersion(ApiVersion apiVersion) {
    return allModels.where((model) => model.apiVersion == apiVersion).toList();
  }

  /// Text-only models
  static List<GeminiModel> get textOnlyModels =>
      getModelsByType(ModelType.textOnly);

  /// Image generation models
  static List<GeminiModel> get imageGenerationModels =>
      getModelsByType(ModelType.imageGeneration);

  /// Multi-modal models
  static List<GeminiModel> get multiModalModels =>
      getModelsByType(ModelType.multiModal);

  /// Find a model by name
  static GeminiModel? findByName(String name) {
    try {
      return allModels.firstWhere((model) => model.name == name);
    } catch (e) {
      return null;
    }
  }
}

/// Types of models based on their capabilities
enum ModelType {
  /// Models that only generate text
  textOnly,

  /// Models that can generate both text and images
  imageGeneration,

  /// Models that can analyze images, videos, and generate text
  multiModal;

  /// Get a human-readable description
  String get description {
    switch (this) {
      case textOnly:
        return 'Text generation only';
      case imageGeneration:
        return 'Text and image generation';
      case multiModal:
        return 'Text, image analysis, and multimodal content';
    }
  }
}
