import 'dart:async';

import '../core/exceptions.dart';
import '../models/content.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import 'conversation_context.dart';

/// Handler for text-based content generation with Gemini API
class TextHandler {
  final HttpService _httpService;
  final String _model;

  /// Creates a new TextHandler
  TextHandler({
    required HttpService httpService,
    String model = 'gemini-2.5-flash',
  })  : _httpService = httpService,
        _model = model;

  /// Generate content from a simple text prompt
  Future<GeminiResponse> generateContent(
    String prompt, {
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
    return generateFromContent([content], config: config, context: context);
  }

  /// Generate content from a list of content objects
  Future<GeminiResponse> generateFromContent(
    List<Content> contents, {
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    if (contents.isEmpty) {
      throw GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
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
        context.addUserMessageWithContent(contents);
        context.addModelResponse(geminiResponse);
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

  /// Generate streaming content from a text prompt
  Stream<GeminiResponse> generateContentStream(
    String prompt, {
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
    yield* generateFromContentStream([content],
        config: config, context: context);
  }

  /// Generate streaming content from a list of content objects
  Stream<GeminiResponse> generateFromContentStream(
    List<Content> contents, {
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    if (contents.isEmpty) {
      throw GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
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
        context.addUserMessageWithContent(contents);
        context.addModelResponse(lastResponse);
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

  /// Generate content with conversation context
  Future<GeminiResponse> generateWithContext(
    ConversationContext context,
    String prompt, {
    GenerationConfig? config,
  }) async {
    if (prompt.trim().isEmpty) {
      throw GeminiValidationException(
        'Prompt cannot be empty',
        {'prompt': 'Prompt is required and cannot be empty'},
      );
    }

    final content = TextContent(prompt);
    return generateFromContent([content], config: config, context: context);
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
    yield* generateFromContentStream([content],
        config: config, context: context);
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
      throw GeminiValidationException(
        'Unsupported content type',
        {'content': 'Content type not supported'},
      );
    }
  }
}
