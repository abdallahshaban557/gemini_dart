import 'gemini_config.dart';

/// Individual capabilities that models can have
enum ModelCapability {
  /// Can generate text content
  textGeneration,

  /// Can generate images
  imageGeneration,

  /// Can analyze and understand images
  imageAnalysis,

  /// Can analyze and understand videos
  videoAnalysis,

  /// Can process and understand audio
  audioProcessing,

  /// Can handle multimodal content (text + images/videos/audio)
  multiModalInput;

  /// Get a human-readable description
  String get description {
    switch (this) {
      case textGeneration:
        return 'Text generation';
      case imageGeneration:
        return 'Image generation';
      case imageAnalysis:
        return 'Image analysis';
      case videoAnalysis:
        return 'Video analysis';
      case audioProcessing:
        return 'Audio processing';
      case multiModalInput:
        return 'Multimodal input';
    }
  }
}

/// Represents a Gemini model with its configuration
class GeminiModel {
  /// Creates a new GeminiModel
  const GeminiModel({
    required this.name,
    required this.apiVersion,
    required this.capabilities,
    this.description,
  });

  /// The model name (e.g., 'gemini-1.5-flash')
  final String name;

  /// The API version this model requires
  final ApiVersion apiVersion;

  /// The capabilities this model supports
  final Set<ModelCapability> capabilities;

  /// Optional description of the model
  final String? description;

  /// Check if this model has a specific capability
  bool hasCapability(ModelCapability capability) =>
      capabilities.contains(capability);

  /// Check if this model can generate text
  bool get canGenerateText => hasCapability(ModelCapability.textGeneration);

  /// Check if this model can generate images
  bool get canGenerateImages => hasCapability(ModelCapability.imageGeneration);

  /// Check if this model can analyze images
  bool get canAnalyzeImages => hasCapability(ModelCapability.imageAnalysis);

  /// Check if this model can analyze videos
  bool get canAnalyzeVideos => hasCapability(ModelCapability.videoAnalysis);

  /// Check if this model can process audio
  bool get canProcessAudio => hasCapability(ModelCapability.audioProcessing);

  /// Check if this model supports multimodal input
  bool get supportsMultiModalInput =>
      hasCapability(ModelCapability.multiModalInput);

  @override
  String toString() {
    final capabilityNames = capabilities.map((c) => c.description).join(', ');
    return '$name ($capabilityNames)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
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
    capabilities: {ModelCapability.textGeneration},
    description: 'Fast text generation model',
  );

  /// Gemini 1.5 Pro model for advanced text and multimodal capabilities
  static const GeminiModel gemini15Pro = GeminiModel(
    name: 'gemini-1.5-pro',
    apiVersion: ApiVersion.v1,
    capabilities: {
      ModelCapability.textGeneration,
      ModelCapability.imageAnalysis,
      ModelCapability.videoAnalysis,
      ModelCapability.audioProcessing,
      ModelCapability.multiModalInput,
    },
    description: 'Advanced text and multimodal capabilities',
  );

  /// Gemini 2.5 Flash model for latest text generation
  static const GeminiModel gemini25Flash = GeminiModel(
    name: 'gemini-2.5-flash',
    apiVersion: ApiVersion.v1,
    capabilities: {ModelCapability.textGeneration},
    description: 'Latest fast text generation model',
  );

  // Image generation models (v1beta API)
  /// Gemini 2.5 Flash Image Preview model for generating images
  static const GeminiModel gemini25FlashImagePreview = GeminiModel(
    name: 'gemini-2.5-flash-image-preview',
    apiVersion: ApiVersion.v1beta,
    capabilities: {
      ModelCapability.textGeneration,
      ModelCapability.imageGeneration,
      ModelCapability.multiModalInput,
    },
    description: 'Image generation model (preview)',
  );

  /// All available models
  static const List<GeminiModel> allModels = [
    gemini15Flash,
    gemini15Pro,
    gemini25Flash,
    gemini25FlashImagePreview,
  ];

  /// Find a model by name
  static GeminiModel? findByName(String name) {
    try {
      return allModels.firstWhere((model) => model.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get all models that have a specific capability
  static List<GeminiModel> getModelsWithCapability(
          ModelCapability capability) =>
      allModels.where((model) => model.hasCapability(capability)).toList();

  /// Get all models that can generate text
  static List<GeminiModel> get textGenerationModels =>
      getModelsWithCapability(ModelCapability.textGeneration);

  /// Get all models that can generate images
  static List<GeminiModel> get imageGenerationModels =>
      getModelsWithCapability(ModelCapability.imageGeneration);

  /// Get all models that support multimodal input
  static List<GeminiModel> get multiModalModels =>
      getModelsWithCapability(ModelCapability.multiModalInput);
}
