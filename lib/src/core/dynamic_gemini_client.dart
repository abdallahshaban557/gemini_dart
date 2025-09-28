import '../models/gemini_config.dart';
import '../models/gemini_models.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../models/gemini_file.dart';
import '../handlers/conversation_context.dart';
import 'gemini_client.dart';
import 'retry_config.dart';

/// Base interface for all Gemini clients
abstract class IGeminiClient {
  /// Initialize the client with an API key
  Future<void> initialize({required String apiKey, GeminiConfig? config});

  /// Check if the client is initialized
  bool get isInitialized;

  /// Get the selected model
  GeminiModel get selectedModel;

  /// Dispose of resources
  void dispose();

  /// Create a conversation context
  ConversationContext createConversationContext();

  /// Generate text from a prompt (available on all models)
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Generate streaming text (available on all models)
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  });
}

/// Interface for models that can generate images
abstract class IImageGenerationClient extends IGeminiClient {
  /// Generate images from text prompt with optional input files
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Create multi-modal content with images
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  });
}

/// Interface for models that can analyze content
abstract class IMultiModalClient extends IGeminiClient {
  /// Analyze images with text prompts
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Analyze documents (PDFs)
  Future<GeminiResponse> analyzeDocument({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Analyze videos
  Future<GeminiResponse> analyzeVideo({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Create complex multi-modal prompts
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    List<GeminiFile>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  });
}

/// Dynamic Gemini client that implements different interfaces based on model type
class DynamicGeminiClient
    implements IGeminiClient, IImageGenerationClient, IMultiModalClient {
  final GeminiClient _client;
  final GeminiModel _model;

  DynamicGeminiClient({
    required GeminiModel model,
    GeminiConfig? config,
    RetryConfig? retryConfig,
  })  : _model = model,
        _client = GeminiClient(
            model: model, config: config, retryConfig: retryConfig);

  @override
  Future<void> initialize({required String apiKey, GeminiConfig? config}) {
    return _client.initialize(apiKey: apiKey, config: config);
  }

  @override
  bool get isInitialized => _client.isInitialized;

  @override
  GeminiModel get selectedModel => _model;

  @override
  void dispose() => _client.dispose();

  @override
  ConversationContext createConversationContext() =>
      _client.createConversationContext();

  @override
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    return _client.generateText(
        prompt: prompt, config: config, context: context);
  }

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) {
    return _client.generateTextStream(prompt: prompt, config: config);
  }

  @override
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!_model.canGenerateImages) {
      throw UnsupportedError(
          'Model ${_model.name} does not support image generation');
    }
    return _client.generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      config: config,
      context: context,
    );
  }

  @override
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!_model.canAnalyzeImages) {
      throw UnsupportedError(
          'Model ${_model.name} does not support image analysis');
    }
    return _client.createMultiModalPrompt(
      text: prompt,
      images: images.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  @override
  Future<GeminiResponse> analyzeDocument({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!_model.canAnalyzeDocuments) {
      throw UnsupportedError(
          'Model ${_model.name} does not support document analysis');
    }
    return _client.createMultiModalPrompt(
      text: prompt,
      images: documents.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  @override
  Future<GeminiResponse> analyzeVideo({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (!_model.canAnalyzeVideos) {
      throw UnsupportedError(
          'Model ${_model.name} does not support video analysis');
    }
    return _client.createMultiModalPrompt(
      text: prompt,
      videos: videos.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
      config: config,
      context: context,
    );
  }

  @override
  Future<GeminiResponse> createMultiModalPrompt({
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

/// Factory function that returns the appropriate interface based on model
IGeminiClient createGeminiClient({
  required GeminiModel model,
  GeminiConfig? config,
  RetryConfig? retryConfig,
}) {
  final client = DynamicGeminiClient(
    model: model,
    config: config,
    retryConfig: retryConfig,
  );

  // Return the appropriate interface based on model capabilities
  switch (model.type) {
    case ModelType.textOnly:
      return client; // Returns IGeminiClient (base interface)
    case ModelType.imageGeneration:
      return client; // Returns IImageGenerationClient (through interface)
    case ModelType.multiModal:
      return client; // Returns IMultiModalClient (through interface)
  }
}
