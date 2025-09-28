import '../models/gemini_config.dart';
import '../models/gemini_models_simple.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../models/gemini_file.dart';
import '../handlers/conversation_context.dart';
import 'gemini_client.dart';

/// Base client interface - all models support these methods
abstract class BaseGeminiClient {
  Future<void> initialize({required String apiKey, GeminiConfig? config});
  bool get isInitialized;
  GeminiModel get selectedModel;
  void dispose();
  ConversationContext createConversationContext();

  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  });

  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  });
}

/// Interface for models that can generate images
abstract class ImageGenerationCapable extends BaseGeminiClient {
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  });

  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  });
}

/// Interface for models that can analyze content
abstract class AnalysisCapable extends BaseGeminiClient {
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  });

  Future<GeminiResponse> analyzeDocument({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  });

  Future<GeminiResponse> analyzeVideo({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  });

  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    List<GeminiFile>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  });
}

/// Text-only client implementation
class _TextOnlyClientImpl implements BaseGeminiClient {
  final GeminiClient _client;
  final GeminiModel _model;

  _TextOnlyClientImpl(this._model) : _client = GeminiClient(model: _model);

  @override
  Future<void> initialize({required String apiKey, GeminiConfig? config}) =>
      _client.initialize(apiKey: apiKey, config: config);

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
  }) =>
      _client.generateText(prompt: prompt, config: config, context: context);

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) =>
      _client.generateTextStream(prompt: prompt, config: config);
}

/// Image generation client implementation
class _ImageGenerationClientImpl implements ImageGenerationCapable {
  final GeminiClient _client;
  final GeminiModel _model;

  _ImageGenerationClientImpl(this._model)
      : _client = GeminiClient(model: _model);

  @override
  Future<void> initialize({required String apiKey, GeminiConfig? config}) =>
      _client.initialize(apiKey: apiKey, config: config);

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
  }) =>
      _client.generateText(prompt: prompt, config: config, context: context);

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) =>
      _client.generateTextStream(prompt: prompt, config: config);

  @override
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.generateImage(
        prompt: prompt,
        geminiFiles: geminiFiles,
        config: config,
        context: context,
      );

  @override
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.createMultiModalPrompt(
        text: text,
        images: images?.map((f) => f.toApiFormat()).toList(),
        config: config,
        context: context,
      );
}

/// Multi-modal client implementation
class _AnalysisClientImpl implements AnalysisCapable {
  final GeminiClient _client;
  final GeminiModel _model;

  _AnalysisClientImpl(this._model) : _client = GeminiClient(model: _model);

  @override
  Future<void> initialize({required String apiKey, GeminiConfig? config}) =>
      _client.initialize(apiKey: apiKey, config: config);

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
  }) =>
      _client.generateText(prompt: prompt, config: config, context: context);

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) =>
      _client.generateTextStream(prompt: prompt, config: config);

  @override
  Future<GeminiResponse> analyzeImage({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.createMultiModalPrompt(
        text: prompt,
        images: images.map((f) => f.toApiFormat()).toList(),
        config: config,
        context: context,
      );

  @override
  Future<GeminiResponse> analyzeDocument({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.createMultiModalPrompt(
        text: prompt,
        images: documents.map((f) => f.toApiFormat()).toList(),
        config: config,
        context: context,
      );

  @override
  Future<GeminiResponse> analyzeVideo({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.createMultiModalPrompt(
        text: prompt,
        videos: videos.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
        config: config,
        context: context,
      );

  @override
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? images,
    List<GeminiFile>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      _client.createMultiModalPrompt(
        text: text,
        images: images?.map((f) => f.toApiFormat()).toList(),
        videos:
            videos?.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
        config: config,
        context: context,
      );
}

/// Model-specific factory functions that return properly typed clients.
///
/// These functions ensure that only supported methods appear in IntelliSense:
/// - Text-only models: Only generateText(), generateTextStream(), etc.
/// - Image generation models: Text methods + generateImage(), createMultiModalPrompt()
/// - Multi-modal models: Text methods + analyzeImage(), analyzeDocument(), analyzeVideo()
///
/// Usage:
/// ```dart
/// // Text-only - NO generateImage method
/// final client = createGemini15FlashClient();
///
/// // Image generation - generateImage method appears
/// final client = createGemini25FlashImagePreviewClient();
/// await client.generateImage(prompt: 'A sunset');
///
/// // Multi-modal - analysis methods appear, generateImage doesn't
/// final client = createGemini15ProClient();
/// await client.analyzeImage(prompt: 'What is this?', images: [...]);
/// ```

/// Create client for gemini-1.5-flash (text-only)
BaseGeminiClient createGemini15FlashClient() =>
    _TextOnlyClientImpl(GeminiModels.gemini15Flash);

/// Create client for gemini-2.5-flash (text-only)
BaseGeminiClient createGemini25FlashClient() =>
    _TextOnlyClientImpl(GeminiModels.gemini25Flash);

/// Create client for gemini-2.5-flash-image-preview (image generation)
ImageGenerationCapable createGemini25FlashImagePreviewClient() =>
    _ImageGenerationClientImpl(GeminiModels.gemini25FlashImagePreview);

/// Create client for gemini-1.5-pro (multi-modal analysis)
AnalysisCapable createGemini15ProClient() =>
    _AnalysisClientImpl(GeminiModels.gemini15Pro);
