import '../models/gemini_config.dart';
import '../models/gemini_models.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../models/gemini_file.dart';
import '../handlers/conversation_context.dart';
import 'gemini_client.dart';
import 'retry_config.dart';

/// Smart Gemini client that shows/hides methods based on model capabilities
///
/// Usage:
/// ```dart
/// // For image generation model - generateImage() will appear in IntelliSense
/// final client = SmartGeminiClient(GeminiModels.gemini25FlashImagePreview);
/// await client.generateImage(prompt: 'A sunset'); // ✅ Available
///
/// // For text-only model - generateImage() won't appear in IntelliSense
/// final client = SmartGeminiClient(GeminiModels.gemini25Flash);
/// // client.generateImage(...); // ❌ Not available in IntelliSense
/// ```
class SmartGeminiClient<T extends GeminiModel> {
  final GeminiClient _client;
  final T _model;

  SmartGeminiClient(
    this._model, {
    GeminiConfig? config,
    RetryConfig? retryConfig,
  }) : _client = GeminiClient(
            model: _model, config: config, retryConfig: retryConfig);

  /// Initialize the client with an API key
  Future<void> initialize({required String apiKey, GeminiConfig? config}) {
    return _client.initialize(apiKey: apiKey, config: config);
  }

  /// Check if the client is initialized
  bool get isInitialized => _client.isInitialized;

  /// Get the selected model
  T get selectedModel => _model;

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

/// Extension for image generation models
extension ImageGenerationExtension on SmartGeminiClient {
  /// Generate images from text prompt with optional input files
  /// Only available when using image generation models
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canGenerateImages) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support image generation');
    }
    return _client.generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      config: config,
      context: context,
    );
  }

  /// Create multi-modal content with images
  /// Only available when using image generation models
  Future<GeminiResponse> createImageMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    return _client.createMultiModalPrompt(
      text: text,
      images: images?.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }
}

/// Extension for multi-modal analysis models
extension MultiModalExtension on SmartGeminiClient {
  /// Analyze images with text prompts
  /// Only available when using multi-modal models
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!selectedModel.canAnalyzeImages) {
      throw UnsupportedError(
          'Model ${selectedModel.name} does not support image analysis');
    }
    return _client.createMultiModalPrompt(
      text: prompt,
      images: images.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze documents (PDFs)
  /// Only available when using multi-modal models
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
      text: text,
      images: documents.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze videos
  /// Only available when using multi-modal models
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

  /// Create complex multi-modal prompts
  /// Only available when using multi-modal models
  Future<GeminiResponse> createAnalysisMultiModalPrompt({
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
