import '../models/gemini_config.dart';
import '../models/gemini_models.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../models/gemini_file.dart';
import '../handlers/conversation_context.dart';
import 'gemini_client.dart';
import 'retry_config.dart';

/// Conditional Gemini client where methods appear/disappear based on model
///
/// This is exactly what you want - one client class where IntelliSense shows
/// different methods based on the model you pass to it.
class ConditionalGeminiClient {
  final GeminiClient _client;
  final GeminiModel _model;

  /// Create a client with a specific model
  /// The available methods will depend on the model's capabilities
  ConditionalGeminiClient({
    required GeminiModel model,
    GeminiConfig? config,
    RetryConfig? retryConfig,
  })  : _model = model,
        _client = GeminiClient(
            model: model, config: config, retryConfig: retryConfig);

  /// Initialize the client with an API key
  Future<void> initialize({required String apiKey, GeminiConfig? config}) {
    return _client.initialize(apiKey: apiKey, config: config);
  }

  /// Check if the client is initialized
  bool get isInitialized => _client.isInitialized;

  /// Get the selected model
  GeminiModel get selectedModel => _model;

  /// Dispose of resources
  void dispose() => _client.dispose();

  /// Create a conversation context
  ConversationContext createConversationContext() =>
      _client.createConversationContext();

  /// Generate text from a prompt (available on all models)
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    return _client.generateText(
        prompt: prompt, config: config, context: context);
  }

  /// Generate streaming text (available on all models)
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) {
    return _client.generateTextStream(prompt: prompt, config: config);
  }
}

/// Extension that adds image generation methods - only shows up for image generation models
extension ImageGenerationMethods on ConditionalGeminiClient {
  /// Generate images from text prompt with optional input files
  ///
  /// This method only appears in IntelliSense when using models that support image generation
  /// like gemini-2.5-flash-image-preview
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    // Runtime check to ensure the model actually supports this
    if (!selectedModel.canGenerateImages) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support image generation. '
          'Use a model like ${GeminiModels.gemini25FlashImagePreview.name} instead.');
    }

    return _client.generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      config: config,
      context: context,
    );
  }

  /// Create multi-modal content with images for generation
  Future<GeminiResponse> createImagePrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canGenerateImages) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support image generation');
    }

    return _client.createMultiModalPrompt(
      text: text,
      images: images?.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }
}

/// Extension that adds analysis methods - only shows up for multi-modal models
extension MultiModalAnalysisMethods on ConditionalGeminiClient {
  /// Analyze images with text prompts
  ///
  /// This method only appears in IntelliSense when using models that support image analysis
  /// like gemini-1.5-pro
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canAnalyzeImages) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support image analysis. '
          'Use a model like ${GeminiModels.gemini15Pro.name} instead.');
    }

    return _client.createMultiModalPrompt(
      text: prompt,
      images: images.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze documents (PDFs)
  Future<GeminiResponse> analyzeDocument({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canAnalyzeDocuments) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support document analysis');
    }

    return _client.createMultiModalPrompt(
      text: prompt,
      images: documents.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze videos
  Future<GeminiResponse> analyzeVideo({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canAnalyzeVideos) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support video analysis');
    }

    return _client.createMultiModalPrompt(
      text: prompt,
      videos: videos.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
      config: config,
      context: context,
    );
  }

  /// Create complex multi-modal analysis prompts
  Future<GeminiResponse> createAnalysisPrompt({
    String? text,
    List<GeminiFile>? images,
    List<GeminiFile>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    return _client.createMultiModalPrompt(
      text: text,
      images: images?.map((f) => f.toApiFormat()).toList(),
      videos: videos?.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
      config: config,
      context: context,
    );
  }
}
