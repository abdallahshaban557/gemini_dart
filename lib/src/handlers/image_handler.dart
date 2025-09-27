import 'dart:typed_data';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import '../utils/image_utils.dart';
import 'conversation_context.dart';

/// Handler for image processing and multi-modal content generation
class ImageHandler {
  /// Creates a new ImageHandler
  ImageHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-flash',
  })  : _httpService = httpService,
        _model = model;

  final HttpService _httpService;
  final String _model;

  /// Generate content from an image with optional text prompt
  Future<GeminiResponse> analyzeImage({
    required Uint8List imageData,
    required String mimeType,
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    // Validate image
    ImageUtils.validateImage(imageData, mimeType);

    final contents = <Content>[];

    // Add text prompt if provided
    if (prompt != null && prompt.trim().isNotEmpty) {
      contents.add(TextContent(prompt.trim()));
    }

    // Add image content
    contents.add(ImageContent(imageData, mimeType));

    return generateFromContent(
        contents: contents, config: config, context: context);
  }

  /// Generate content from multiple images with optional text prompt
  Future<GeminiResponse> analyzeImages(
    List<({Uint8List data, String mimeType})> images, {
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (images.isEmpty) {
      throw const GeminiValidationException(
        'At least one image is required',
        {'images': 'Images list cannot be empty'},
      );
    }

    final contents = <Content>[];

    // Add text prompt if provided
    if (prompt != null && prompt.trim().isNotEmpty) {
      contents.add(TextContent(prompt.trim()));
    }

    // Validate and add all images
    for (final image in images) {
      ImageUtils.validateImage(image.data, image.mimeType);
      contents.add(ImageContent(image.data, image.mimeType));
    }

    return generateFromContent(
        contents: contents, config: config, context: context);
  }

  /// Generate content from mixed content types (text, images)
  Future<GeminiResponse> generateFromContent({
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

    // Validate all image contents
    for (final content in contents) {
      if (content is ImageContent) {
        ImageUtils.validateImage(content.data, content.mimeType);
      }
    }

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
        'Failed to generate content: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Generate streaming content from mixed content types
  Stream<GeminiResponse> generateFromContentStream({
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

    // Validate all image contents
    for (final content in contents) {
      if (content is ImageContent) {
        ImageUtils.validateImage(content.data, content.mimeType);
      }
    }

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
        'Failed to generate streaming content: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Compare two images and provide analysis
  Future<GeminiResponse> compareImages(
    Uint8List image1Data,
    String image1MimeType,
    Uint8List image2Data,
    String image2MimeType, {
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    // Validate both images
    ImageUtils.validateImage(image1Data, image1MimeType);
    ImageUtils.validateImage(image2Data, image2MimeType);

    final contents = <Content>[];

    // Add comparison prompt or default
    final comparisonPrompt = prompt ??
        'Compare these two images and describe the differences and '
            'similarities.';
    contents.add(TextContent(comparisonPrompt));

    // Add both images
    contents
      ..add(ImageContent(image1Data, image1MimeType))
      ..add(ImageContent(image2Data, image2MimeType));

    return generateFromContent(
        contents: contents, config: config, context: context);
  }

  /// Extract text from an image (OCR functionality)
  Future<GeminiResponse> extractTextFromImage({
    required Uint8List imageData,
    required String mimeType,
    GenerationConfig? config,
    ConversationContext? context,
  }) =>
      analyzeImage(
        imageData: imageData,
        mimeType: mimeType,
        prompt: 'Extract and transcribe all text visible in this image. '
            'Maintain the original formatting and structure as much as '
            'possible.',
        config: config,
        context: context,
      );

  /// Describe an image in detail
  Future<GeminiResponse> describeImage({
    required Uint8List imageData,
    required String mimeType,
    String? focusArea,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    final prompt = focusArea != null
        ? 'Describe this image in detail, paying special attention to: '
            '$focusArea'
        : 'Describe this image in detail, including objects, people, '
            'setting, colors, and any notable features.';

    return analyzeImage(
      imageData: imageData,
      mimeType: mimeType,
      prompt: prompt,
      config: config,
      context: context,
    );
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
