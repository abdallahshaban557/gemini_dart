import 'dart:typed_data';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/gemini_file.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import '../utils/image_utils.dart';
import 'base_content_handler.dart';
import 'conversation_context.dart';

/// Handler for image processing and multi-modal content generation
class ImageHandler extends BaseContentHandler {
  /// Creates a new ImageHandler
  ImageHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-flash',
  }) : super(httpService: httpService, model: model);

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
    // Validate all image contents
    for (final content in contents) {
      if (content is ImageContent) {
        ImageUtils.validateImage(content.data, content.mimeType);
      }
    }

    return super.generateContent(
      contents: contents,
      config: config,
      context: context,
    );
  }

  /// Generate streaming content from mixed content types
  Stream<GeminiResponse> generateFromContentStream({
    required List<Content> contents,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    // Validate all image contents
    for (final content in contents) {
      if (content is ImageContent) {
        ImageUtils.validateImage(content.data, content.mimeType);
      }
    }

    yield* super.generateContentStream(
      contents: contents,
      config: config,
      context: context,
    );
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

  /// Generate an image from a text prompt with optional input files
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    List<({Uint8List data, String mimeType})>? files,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    // Build content list
    final contents = <Content>[];

    // Add text prompt
    contents.add(TextContent(prompt));

    // Add GeminiFile objects if provided (recommended)
    if (geminiFiles != null) {
      for (final geminiFile in geminiFiles) {
        contents.add(ImageContent(geminiFile.data, geminiFile.mimeType));
      }
    }

    // Add raw files if provided (legacy support)
    if (files != null) {
      for (final file in files) {
        contents.add(ImageContent(file.data, file.mimeType));
      }
    }

    return generateFromContent(
        contents: contents, config: config, context: context);
  }
}
