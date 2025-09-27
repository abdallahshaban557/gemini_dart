import 'dart:typed_data';

import '../handlers/conversation_context.dart';
import 'content.dart';
import 'gemini_config.dart';
import 'generation_config.dart';
import 'response.dart';

/// Base interface for all model types
abstract class ModelInterface {
  /// The model name/identifier
  final String name;

  /// The client instance for making requests
  final dynamic client;

  const ModelInterface(this.name, this.client);

  /// Initialize the model with an API key
  ///
  /// This must be called before using any generation methods.
  Future<void> initialize({
    required String apiKey,
    GeminiConfig? config,
  }) async {
    return client.initialize(apiKey: apiKey, config: config);
  }

  /// Check if the model is initialized and ready to use
  bool get isInitialized => client.isInitialized;

  /// Dispose of resources and close connections
  void dispose() => client.dispose();

  /// Generate text content
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  });

  /// Generate streaming text content
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  });
}

/// Interface for text-only models
class TextOnlyModel extends ModelInterface {
  const TextOnlyModel(String name, dynamic client) : super(name, client);

  @override
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.textHandler
        .generateContent(prompt: prompt, config: config, context: context);
  }

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    yield* client.textHandler.generateContentStream(
        prompt: prompt, config: config, context: context);
  }

}

/// Interface for models that can generate images
class ImageGenerationModel extends ModelInterface {
  const ImageGenerationModel(String name, dynamic client) : super(name, client);

  @override
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.textHandler
        .generateContent(prompt: prompt, config: config, context: context);
  }

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    yield* client.textHandler.generateContentStream(
        prompt: prompt, config: config, context: context);
  }

  /// Generate an image from text prompt
  Future<GeminiResponse> generateImage({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.generateImage(
        prompt: prompt, config: config, context: context);
  }

}

/// Interface for models that can analyze images and videos
class MultiModalModel extends ModelInterface {
  const MultiModalModel(String name, dynamic client) : super(name, client);

  @override
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.textHandler
        .generateContent(prompt: prompt, config: config, context: context);
  }

  @override
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    yield* client.textHandler.generateContentStream(
        prompt: prompt, config: config, context: context);
  }

  /// Analyze an image with optional text prompt
  Future<GeminiResponse> analyzeImage({
    required Uint8List imageData,
    required String mimeType,
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.analyzeImage(
      imageData: imageData,
      mimeType: mimeType,
      prompt: prompt,
      config: config,
      context: context,
    );
  }

  /// Analyze a video
  Future<GeminiResponse> analyzeVideo({
    required String fileUri,
    required String mimeType,
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    final contents = <Content>[
      if (prompt != null) TextContent(prompt),
      VideoContent(fileUri, mimeType),
    ];

    return client.multiModalHandler.generateContent(
      contents: contents,
      config: config,
      context: context,
    );
  }


  /// Create a multi-modal prompt with text, images, and videos
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<({Uint8List data, String mimeType})>? images,
    List<({String fileUri, String mimeType})>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    return client.createMultiModalPrompt(
      text: text,
      images: images,
      videos: videos,
      config: config,
      context: context,
    );
  }
}
