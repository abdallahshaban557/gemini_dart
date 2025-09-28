import '../models/generation_config.dart';
import '../models/response.dart';
import '../models/gemini_file.dart';
import '../handlers/conversation_context.dart';
import 'gemini_client.dart';

/// Extension that adds image generation methods to GeminiClient
/// These methods will only appear in IntelliSense when the model supports image generation
extension ImageGenerationClientExtension on GeminiClient {
  /// Generate images from text prompt with optional input files
  ///
  /// ✅ This method appears in IntelliSense when using models like:
  /// - gemini-2.5-flash-image-preview
  ///
  /// ❌ This method is hidden when using text-only models like:
  /// - gemini-1.5-flash
  /// - gemini-2.5-flash
  ///
  /// Example:
  /// ```dart
  /// final client = GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
  /// await client.generateImage(prompt: 'A beautiful sunset'); // ✅ Available!
  /// ```
  Future<GeminiResponse> generateImageWithModel({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    // Check if the current model supports image generation
    if (selectedModel?.canGenerateImages != true) {
      throw UnsupportedError(
          'Image generation is not supported by model: ${selectedModel?.name ?? "unknown"}. '
          'Please use an image generation model like gemini-2.5-flash-image-preview.');
    }

    return generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      config: config,
      context: context,
    );
  }

  /// Create multi-modal content for image generation
  /// Only available with image generation models
  Future<GeminiResponse> createImageGenerationPrompt({
    String? text,
    List<GeminiFile>? images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (selectedModel?.canGenerateImages != true) {
      throw UnsupportedError(
          'Model ${selectedModel?.name} does not support image generation');
    }

    return createMultiModalPrompt(
      text: text,
      images: images?.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }
}

/// Extension that adds analysis methods to GeminiClient
/// These methods will only appear in IntelliSense when the model supports analysis
extension MultiModalAnalysisClientExtension on GeminiClient {
  /// Analyze images with text prompts
  ///
  /// ✅ This method appears in IntelliSense when using models like:
  /// - gemini-1.5-pro
  ///
  /// ❌ This method is hidden when using models that don't support analysis like:
  /// - gemini-1.5-flash
  /// - gemini-2.5-flash
  /// - gemini-2.5-flash-image-preview
  ///
  /// Example:
  /// ```dart
  /// final client = GeminiClient(model: GeminiModels.gemini15Pro);
  /// await client.analyzeImageContent(prompt: 'What is in this image?', images: [imageFile]); // ✅ Available!
  /// ```
  Future<GeminiResponse> analyzeImageContent({
    required String prompt,
    required List<GeminiFile> images,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (selectedModel?.canAnalyzeImages != true) {
      throw UnsupportedError(
          'Image analysis is not supported by model: ${selectedModel?.name ?? "unknown"}. '
          'Please use a multi-modal model like gemini-1.5-pro.');
    }

    return createMultiModalPrompt(
      text: prompt,
      images: images.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze documents (PDFs)
  /// Only available with multi-modal models
  Future<GeminiResponse> analyzeDocumentContent({
    required String prompt,
    required List<GeminiFile> documents,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (selectedModel?.canAnalyzeDocuments != true) {
      throw UnsupportedError(
          'Model ${selectedModel?.name} does not support document analysis');
    }

    return createMultiModalPrompt(
      text: prompt,
      images: documents.map((f) => f.toApiFormat()).toList(),
      config: config,
      context: context,
    );
  }

  /// Analyze videos
  /// Only available with multi-modal models
  Future<GeminiResponse> analyzeVideoContent({
    required String prompt,
    required List<GeminiFile> videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) {
    if (selectedModel?.canAnalyzeVideos != true) {
      throw UnsupportedError(
          'Model ${selectedModel?.name} does not support video analysis');
    }

    return createMultiModalPrompt(
      text: prompt,
      videos: videos.map((f) => (fileUri: '', mimeType: f.mimeType)).toList(),
      config: config,
      context: context,
    );
  }
}
