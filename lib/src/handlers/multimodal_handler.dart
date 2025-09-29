import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/gemini_file.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import '../utils/image_utils.dart';
import 'base_content_handler.dart';
import 'conversation_context.dart';

/// Handler for multi-modal content generation combining text, images, and
/// videos
class MultiModalHandler extends BaseContentHandler {
  /// Creates a new MultiModalHandler
  MultiModalHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-pro',
  }) : super(httpService: httpService, model: model);

  /// Generate content from mixed content types
  Future<GeminiResponse> generateContent({
    required List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return super.generateContent(
      contents: contents,
      config: config,
      context: context,
    );
  }

  /// Generate streaming content from mixed content types
  Stream<GeminiResponse> generateContentStream({
    required List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    yield* super.generateContentStream(
      contents: contents,
      config: config,
      context: context,
    );
  }

  /// Create a multi-modal prompt with text and files
  Future<GeminiResponse> createPrompt({
    String? text,
    List<GeminiFile>? files,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    final contents = <Content>[];

    // Add text if provided
    if (text != null && text.trim().isNotEmpty) {
      contents.add(TextContent(text.trim()));
    }

    // Add GeminiFile objects if provided
    if (files != null) {
      for (final file in files) {
        if (file.isImage) {
          ImageUtils.validateImage(file.data, file.mimeType);
          contents.add(ImageContent(file.data, file.mimeType));
        } else if (file.isVideo) {
          // For videos, we need to handle both local files and URIs
          // If it's a local file, we might need to upload it first
          // For now, we'll create VideoContent with a placeholder URI
          // This would need to be enhanced based on your video handling strategy
          final fileName = file.fileName ?? 'unknown_video';
          contents.add(VideoContent('file://$fileName', file.mimeType));
        } else if (file.isAudio) {
          // Handle audio files - similar to video
          final fileName = file.fileName ?? 'unknown_audio';
          contents.add(VideoContent('file://$fileName', file.mimeType));
        } else {
          // Handle other file types (PDFs, etc.)
          ImageUtils.validateImage(file.data, file.mimeType);
          contents.add(ImageContent(file.data, file.mimeType));
        }
      }
    }

    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'At least one content type must be provided',
        {'content': 'Text or files must be provided'},
      );
    }

    return generateContent(
        contents: contents, config: config, context: context);
  }

  /// Analyze multiple media files together
  Future<GeminiResponse> analyzeMedia({
    required String analysisPrompt,
    required List<GeminiFile> files,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (files.isEmpty) {
      throw const GeminiValidationException(
        'At least one media file must be provided for analysis',
        {'media': 'Files must be provided'},
      );
    }

    return createPrompt(
      text: analysisPrompt,
      files: files,
      config: config,
      context: context,
    );
  }

  /// Create a conversation with mixed media
  Future<GeminiResponse> conversationWithMedia(
    ConversationContext context, {
    String? text,
    List<GeminiFile>? files,
    GenerationConfig? config,
  }) =>
      createPrompt(
        text: text,
        files: files,
        config: config,
        context: context,
      );
}
