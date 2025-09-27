import 'dart:typed_data';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import '../utils/image_utils.dart';
import 'conversation_context.dart';

/// Handler for multi-modal content generation combining text, images, and
/// videos
class MultiModalHandler {
  /// Creates a new MultiModalHandler
  MultiModalHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-flash',
  })  : _httpService = httpService,
        _model = model;

  final HttpService _httpService;
  final String _model;

  /// Generate content from mixed content types
  Future<GeminiResponse> generateContent({
    required List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
    }

    // Validate all contents
    _validateContents(contents);

    // Validate generation config if provided
    config?.validate();

    final requestBody = _buildRequestBody(contents, config, context);

    try {
      final response = await _httpService.post(
        'models/$_model:generateContent',
        body: requestBody,
      );

      final geminiResponse = GeminiResponse.fromJson(response);

      // Add to conversation context if provided
      if (context != null) {
        context
          ..addUserMessageWithContent(contents)
          ..addModelResponse(geminiResponse);
      }

      return geminiResponse;
    } catch (e) {
      if (e is GeminiException) {
        rethrow;
      }
      throw GeminiNetworkException(
        'Failed to generate multi-modal content: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Generate streaming content from mixed content types
  Stream<GeminiResponse> generateContentStream({
    required List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
    }

    // Validate all contents
    _validateContents(contents);

    // Validate generation config if provided
    config?.validate();

    final requestBody = _buildRequestBody(contents, config, context);
    GeminiResponse? lastResponse;

    try {
      await for (final chunk in _httpService.postStream(
        'models/$_model:streamGenerateContent',
        body: requestBody,
      )) {
        final response = GeminiResponse.fromJson(chunk);
        lastResponse = response;
        yield response;
      }

      // Add to conversation context after streaming is complete
      if (context != null && lastResponse != null) {
        context
          ..addUserMessageWithContent(contents)
          ..addModelResponse(lastResponse);
      }
    } catch (e) {
      if (e is GeminiException) {
        rethrow;
      }
      throw GeminiNetworkException(
        'Failed to generate streaming multi-modal content: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Create a multi-modal prompt with text and images
  Future<GeminiResponse> createPrompt({
    String? text,
    List<({Uint8List data, String mimeType})>? images,
    List<({String fileUri, String mimeType})>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    final contents = <Content>[];

    // Add text if provided
    if (text != null && text.trim().isNotEmpty) {
      contents.add(TextContent(text.trim()));
    }

    // Add images if provided
    if (images != null) {
      for (final image in images) {
        ImageUtils.validateImage(image.data, image.mimeType);
        contents.add(ImageContent(image.data, image.mimeType));
      }
    }

    // Add videos if provided
    if (videos != null) {
      for (final video in videos) {
        contents.add(VideoContent(video.fileUri, video.mimeType));
      }
    }

    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'At least one content type must be provided',
        {'content': 'Text, images, or videos must be provided'},
      );
    }

    return generateContent(
        contents: contents, config: config, context: context);
  }

  /// Analyze multiple media types together
  Future<GeminiResponse> analyzeMedia({
    required String analysisPrompt,
    List<({Uint8List data, String mimeType})>? images,
    List<({String fileUri, String mimeType})>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    final contents = <Content>[TextContent(analysisPrompt)];

    // Add images if provided
    if (images != null) {
      for (final image in images) {
        ImageUtils.validateImage(image.data, image.mimeType);
        contents.add(ImageContent(image.data, image.mimeType));
      }
    }

    // Add videos if provided
    if (videos != null) {
      for (final video in videos) {
        contents.add(VideoContent(video.fileUri, video.mimeType));
      }
    }

    if (contents.length == 1) {
      throw const GeminiValidationException(
        'At least one media file must be provided for analysis',
        {'media': 'Images or videos must be provided'},
      );
    }

    return generateContent(
        contents: contents, config: config, context: context);
  }

  /// Create a conversation with mixed media
  Future<GeminiResponse> conversationWithMedia(
    ConversationContext context, {
    String? text,
    List<({Uint8List data, String mimeType})>? images,
    List<({String fileUri, String mimeType})>? videos,
    GenerationConfig? config,
  }) =>
      createPrompt(
        text: text,
        images: images,
        videos: videos,
        config: config,
        context: context,
      );

  /// Get content statistics for the current request
  Map<String, dynamic> getContentStatistics(List<Content> contents) {
    var textCount = 0;
    var imageCount = 0;
    var videoCount = 0;
    var totalSize = 0;
    var totalTextLength = 0;

    for (final content in contents) {
      if (content is TextContent) {
        textCount++;
        totalTextLength += content.text.length;
      } else if (content is ImageContent) {
        imageCount++;
        totalSize += content.data.length;
      } else if (content is VideoContent) {
        videoCount++;
        // Video size would need to be tracked separately
      }
    }

    return {
      'textCount': textCount,
      'imageCount': imageCount,
      'videoCount': videoCount,
      'totalSize': totalSize,
      'totalTextLength': totalTextLength,
      'formattedSize': ImageUtils.formatFileSize(totalSize),
    };
  }

  /// Validate all content items
  void _validateContents(List<Content> contents) {
    for (final content in contents) {
      if (content is ImageContent) {
        ImageUtils.validateImage(content.data, content.mimeType);
      } else if (content is VideoContent) {
        // Video validation would be implemented in video handler
        if (content.fileUri.isEmpty) {
          throw const GeminiValidationException(
            'Video file URI cannot be empty',
            {'video': 'Valid file URI is required'},
          );
        }
      } else if (content is TextContent) {
        // Text validation is minimal - empty text is allowed
        continue;
      } else {
        throw GeminiValidationException(
          'Unsupported content type: ${content.runtimeType}',
          const {'content': 'Content type not supported'},
        );
      }
    }
  }

  /// Build the request body for API calls
  Map<String, dynamic> _buildRequestBody(
    List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  ) {
    final body = <String, dynamic>{};

    // Add conversation history if available
    if (context != null && context.isNotEmpty) {
      final history = context.toApiFormat();
      // Add current user message to history
      history.add({
        'role': 'user',
        'parts': contents.map(_contentToPart).toList(),
      });
      body['contents'] = history;
    } else {
      // Single message format
      body['contents'] = [
        {
          'parts': contents.map(_contentToPart).toList(),
        }
      ];
    }

    if (config != null) {
      body['generationConfig'] = config.toJson();
    }

    return body;
  }

  /// Convert Content object to API part format
  Map<String, dynamic> _contentToPart(Content content) {
    if (content is TextContent) {
      return {'text': content.text};
    } else if (content is ImageContent) {
      return {
        'inlineData': {
          'mimeType': content.mimeType,
          'data': content.data,
        }
      };
    } else if (content is VideoContent) {
      return {
        'fileData': {
          'mimeType': content.mimeType,
          'fileUri': content.fileUri,
        }
      };
    } else {
      throw const GeminiValidationException(
        'Unsupported content type',
        {'content': 'Content type not supported'},
      );
    }
  }
}
