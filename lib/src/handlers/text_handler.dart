import 'dart:async';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import 'base_content_handler.dart';
import 'conversation_context.dart';

/// Handler for text-based content generation with Gemini API
class TextHandler extends BaseContentHandler {
  /// Creates a new TextHandler
  TextHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-pro',
  }) : super(httpService: httpService, model: model);

  /// Generate content from a simple text prompt
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    final content = TextContent(prompt);
    return super
        .generateContent(contents: [content], config: config, context: context);
  }

  /// Generate content from a list of content objects
  Future<GeminiResponse> generateFromContent({
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

  /// Generate streaming content from a text prompt
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    final content = TextContent(prompt);
    yield* super.generateContentStream(
        contents: [content], config: config, context: context);
  }

  /// Generate streaming content from a list of content objects
  Stream<GeminiResponse> generateFromContentStream({
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

  /// Generate content with conversation context
  Future<GeminiResponse> generateWithContext({
    required ConversationContext context,
    required String prompt,
    GenerationConfig? config,
  }) async {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    final content = TextContent(prompt);
    return super
        .generateContent(contents: [content], config: config, context: context);
  }

  /// Generate streaming content with conversation context
  Stream<GeminiResponse> generateStreamWithContext(
    ConversationContext context,
    String prompt, {
    GenerationConfig? config,
  }) async* {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    final content = TextContent(prompt);
    yield* super.generateContentStream(
        contents: [content], config: config, context: context);
  }
}
