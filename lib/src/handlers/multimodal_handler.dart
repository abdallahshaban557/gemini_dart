import 'dart:convert';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/gemini_file.dart';
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
    String model = 'gemini-2.5-pro',
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
        'inline_data': {
          'mime_type': content.mimeType,
          'data': base64Encode(content.data),
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
