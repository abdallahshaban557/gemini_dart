import 'dart:io';
import 'dart:typed_data';

import '../handlers/conversation_context.dart';
import '../handlers/image_handler.dart';
import '../handlers/multimodal_handler.dart';
import '../handlers/text_handler.dart';
import '../models/content.dart';
import '../models/gemini_config.dart';
import '../models/generation_config.dart';
import '../models/response.dart';
import '../services/http_service.dart';
import 'auth.dart';
import 'exceptions.dart';
import 'retry_config.dart';

/// Main client interface for interacting with Google's Gemini AI models
///
/// This client provides a unified interface for text, image, and multi-modal
/// content generation using the Gemini API. It integrates all handlers and
/// services to provide a simple, high-level API for developers.
class GeminiClient {
  HttpService? _httpService;
  AuthenticationHandler? _auth;
  TextHandler? _textHandler;
  ImageHandler? _imageHandler;
  MultiModalHandler? _multiModalHandler;

  GeminiConfig _config;
  bool _initialized = false;

  /// Creates a new GeminiClient with optional configuration
  GeminiClient({
    GeminiConfig? config,
    RetryConfig? retryConfig,
  }) : _config = config ?? const GeminiConfig() {
    _initializeServices(retryConfig);
  }

  /// Initialize all internal services
  void _initializeServices(RetryConfig? retryConfig) {
    _auth = AuthenticationHandler();
    _httpService = HttpService(
      auth: _auth!,
      config: _config,
      retryConfig: retryConfig,
    );
    _textHandler = TextHandler(httpService: _httpService!);
    _imageHandler = ImageHandler(httpService: _httpService!);
    _multiModalHandler = MultiModalHandler(httpService: _httpService!);
  }

  /// Initialize the client with an API key
  ///
  /// This must be called before using any generation methods.
  /// The API key will be validated and stored for subsequent requests.
  Future<void> initialize(String apiKey, {GeminiConfig? config}) async {
    if (apiKey.isEmpty) {
      throw const GeminiAuthException('API key cannot be empty');
    }

    // Update configuration if provided
    if (config != null) {
      _config = config;
      _config.validate();

      // Recreate services with new config
      _initializeServices(null);
    }

    // Set and validate API key
    _auth!.setApiKey(apiKey);

    // Test the connection by making a simple request
    try {
      await _httpService!.get('models');
      _initialized = true;
    } catch (e) {
      throw GeminiAuthException(
        'Failed to initialize client: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Generate content from a simple text prompt
  ///
  /// This is the most basic method for text generation.
  /// For more advanced use cases, use [generateFromContent] or the handler methods.
  Future<GeminiResponse> generateContent(
    String prompt, {
    GenerationConfig? config,
  }) async {
    _ensureInitialized();
    return _textHandler!.generateContent(prompt, config: config);
  }

  /// Generate content from a list of content objects
  ///
  /// This method supports multi-modal content including text, images, and videos.
  /// It automatically routes to the appropriate handler based on content types.
  Future<GeminiResponse> generateFromContent(
    List<Content> contents, {
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();

    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
    }

    // Determine which handler to use based on content types
    final hasImages = contents.any((c) => c is ImageContent);
    final hasVideos = contents.any((c) => c is VideoContent);
    final hasText = contents.any((c) => c is TextContent);

    if (hasImages || hasVideos) {
      // Use multi-modal handler for mixed content
      return _multiModalHandler!.generateContent(
        contents,
        config: config,
        context: context,
      );
    } else if (hasText) {
      // Use text handler for text-only content
      return _textHandler!.generateFromContent(
        contents,
        config: config,
        context: context,
      );
    } else {
      throw const GeminiValidationException(
        'Unsupported content types',
        {'contents': 'No supported content types found'},
      );
    }
  }

  /// Generate streaming content from a text prompt
  ///
  /// Returns a stream of partial responses for real-time content generation.
  Stream<GeminiResponse> generateContentStream(
    String prompt, {
    GenerationConfig? config,
  }) async* {
    _ensureInitialized();
    yield* _textHandler!.generateContentStream(prompt, config: config);
  }

  /// Generate streaming content from a list of content objects
  Stream<GeminiResponse> generateFromContentStream(
    List<Content> contents, {
    GenerationConfig? config,
    ConversationContext? context,
  }) async* {
    _ensureInitialized();

    if (contents.isEmpty) {
      throw const GeminiValidationException(
        'Contents cannot be empty',
        {'contents': 'At least one content item is required'},
      );
    }

    // Determine which handler to use based on content types
    final hasImages = contents.any((c) => c is ImageContent);
    final hasVideos = contents.any((c) => c is VideoContent);
    final hasText = contents.any((c) => c is TextContent);

    if (hasImages || hasVideos) {
      // Use multi-modal handler for mixed content
      yield* _multiModalHandler!.generateContentStream(
        contents,
        config: config,
        context: context,
      );
    } else if (hasText) {
      // Use text handler for text-only content
      yield* _textHandler!.generateFromContentStream(
        contents,
        config: config,
        context: context,
      );
    } else {
      throw const GeminiValidationException(
        'Unsupported content types',
        {'contents': 'No supported content types found'},
      );
    }
  }

  /// Analyze an image with optional text prompt
  ///
  /// Convenience method for image analysis. For more advanced image operations,
  /// use the [imageHandler] directly.
  Future<GeminiResponse> analyzeImage(
    Uint8List imageData,
    String mimeType, {
    String? prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();
    return _imageHandler!.analyzeImage(
      imageData,
      mimeType,
      prompt: prompt,
      config: config,
      context: context,
    );
  }

  /// Generate an image from a text prompt
  ///
  /// This method uses Gemini's image generation capabilities to create images
  /// from text descriptions. The response will contain both a text description
  /// and the generated image data.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.generateImage('A sunset over mountains');
  /// print(response.text); // Text description
  /// final imageData = response.candidates.first.content.parts
  ///     .whereType<ImagePart>().first.data; // Image bytes
  /// ```
  Future<GeminiResponse> generateImage(
    String prompt, {
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();

    try {
      // Use v1beta API version and correct model for image generation
      final imageGenService = HttpService(
        auth: _auth!,
        config: _config.copyWith(apiVersion: 'v1beta'),
      );

      final response = await imageGenService.post(
        'models/gemini-2.5-flash-image-preview:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          if (config != null) 'generationConfig': config.toJson(),
        },
      );

      final geminiResponse = GeminiResponse.fromJson(response);

      // Add to conversation context if provided
      if (context != null) {
        context.addUserMessage(prompt);
        context.addModelResponse(geminiResponse);
      }

      return geminiResponse;
    } catch (e) {
      throw GeminiNetworkException(
        'Failed to generate image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Generate an image with advanced options
  ///
  /// This method provides more control over image generation including
  /// aspect ratio, style, and other parameters.
  Future<GeminiResponse> generateImageAdvanced(
    String prompt, {
    String? aspectRatio, // e.g., "1:1", "16:9", "9:16"
    String? style, // e.g., "photographic", "digital_art", "sketch"
    int? seed, // For reproducible results
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();

    try {
      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          ...?config?.toJson(),
          if (aspectRatio != null) 'aspectRatio': aspectRatio,
          if (style != null) 'style': style,
          if (seed != null) 'seed': seed,
        },
      };

      // Use v1beta API version for image generation
      final imageGenService = HttpService(
        auth: _auth!,
        config: _config.copyWith(apiVersion: 'v1beta'),
      );

      final response = await imageGenService.post(
        'models/gemini-2.5-flash-image-preview:generateContent',
        body: requestBody,
      );

      final geminiResponse = GeminiResponse.fromJson(response);

      // Add to conversation context if provided
      if (context != null) {
        context.addUserMessage(prompt);
        context.addModelResponse(geminiResponse);
      }

      return geminiResponse;
    } catch (e) {
      throw GeminiNetworkException(
        'Failed to generate image: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Create a multi-modal prompt with text, images, and videos
  ///
  /// This is a convenience method for creating complex multi-modal requests.
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<({Uint8List data, String mimeType})>? images,
    List<({String fileUri, String mimeType})>? videos,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();
    return _multiModalHandler!.createPrompt(
      text: text,
      images: images,
      videos: videos,
      config: config,
      context: context,
    );
  }

  /// Upload a file for use in video content generation
  ///
  /// This method uploads large files (typically videos) to the Gemini API
  /// and returns a file URI that can be used in VideoContent objects.
  Future<FileUploadResponse> uploadFile(
    File file, {
    String? mimeType,
  }) async {
    _ensureInitialized();

    try {
      final response = await _httpService!.uploadFile(
        'upload/files',
        file,
        mimeType: mimeType,
      );

      return FileUploadResponse.fromJson(response);
    } catch (e) {
      throw GeminiNetworkException(
        'Failed to upload file: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Get available models from the Gemini API
  ///
  /// Returns a list of available models that can be used for content generation.
  Future<List<GeminiModel>> getModels() async {
    _ensureInitialized();

    try {
      final response = await _httpService!.get('models');
      final modelsJson = response['models'] as List<dynamic>?;

      if (modelsJson == null) {
        return [];
      }

      return modelsJson
          .map((m) => GeminiModel.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw GeminiNetworkException(
        'Failed to get models: ${e.toString()}',
        originalError: e,
      );
    }
  }

  /// Create a new conversation context
  ///
  /// Conversation contexts maintain chat history for multi-turn conversations.
  ConversationContext createConversationContext() => ConversationContext();

  /// Get the current configuration
  GeminiConfig get config => _config;

  /// Update the client configuration
  ///
  /// Note: This will recreate internal services with the new configuration.
  void updateConfig(GeminiConfig newConfig) {
    newConfig.validate();
    _config = newConfig;

    // Recreate services with new config
    _initializeServices(null);
  }

  /// Get direct access to the text handler for advanced text operations
  TextHandler get textHandler {
    _ensureInitialized();
    return _textHandler!;
  }

  /// Get direct access to the image handler for advanced image operations
  ImageHandler get imageHandler {
    _ensureInitialized();
    return _imageHandler!;
  }

  /// Get direct access to the multi-modal handler for advanced operations
  MultiModalHandler get multiModalHandler {
    _ensureInitialized();
    return _multiModalHandler!;
  }

  /// Check if the client is initialized and ready to use
  bool get isInitialized => _initialized;

  /// Dispose of resources and close connections
  void dispose() {
    _httpService?.dispose();
    _initialized = false;
  }

  /// Ensure the client is initialized before making requests
  void _ensureInitialized() {
    if (!_initialized) {
      throw const GeminiValidationException(
        'Client not initialized. Call initialize() first.',
        {},
      );
    }
  }
}

/// Response from file upload operations
class FileUploadResponse {
  /// The URI of the uploaded file
  final String fileUri;

  /// The MIME type of the uploaded file
  final String mimeType;

  /// The size of the uploaded file in bytes
  final int sizeBytes;

  /// The name of the uploaded file
  final String? fileName;

  /// Creates a new FileUploadResponse
  const FileUploadResponse({
    required this.fileUri,
    required this.mimeType,
    required this.sizeBytes,
    this.fileName,
  });

  /// Create FileUploadResponse from JSON
  factory FileUploadResponse.fromJson(Map<String, dynamic> json) {
    final fileUri = json['file']?['uri'] as String?;
    final mimeType = json['file']?['mimeType'] as String?;
    final sizeBytes = json['file']?['sizeBytes'] as int?;
    final fileName = json['file']?['displayName'] as String?;

    if (fileUri == null) {
      throw ArgumentError('File URI is required in upload response');
    }
    if (mimeType == null) {
      throw ArgumentError('MIME type is required in upload response');
    }
    if (sizeBytes == null) {
      throw ArgumentError('Size is required in upload response');
    }

    return FileUploadResponse(
      fileUri: fileUri,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      fileName: fileName,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'file': {
          'uri': fileUri,
          'mimeType': mimeType,
          'sizeBytes': sizeBytes,
          if (fileName != null) 'displayName': fileName,
        }
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileUploadResponse &&
        other.fileUri == fileUri &&
        other.mimeType == mimeType &&
        other.sizeBytes == sizeBytes &&
        other.fileName == fileName;
  }

  @override
  int get hashCode => Object.hash(fileUri, mimeType, sizeBytes, fileName);

  @override
  String toString() => 'FileUploadResponse('
      'fileUri: $fileUri, '
      'mimeType: $mimeType, '
      'sizeBytes: $sizeBytes, '
      'fileName: $fileName)';
}

/// Information about available Gemini models
class GeminiModel {
  /// The model name/identifier
  final String name;

  /// The display name of the model
  final String displayName;

  /// Description of the model
  final String? description;

  /// Version of the model
  final String? version;

  /// Input token limit
  final int? inputTokenLimit;

  /// Output token limit
  final int? outputTokenLimit;

  /// Supported generation methods
  final List<String> supportedGenerationMethods;

  /// Creates a new GeminiModel
  const GeminiModel({
    required this.name,
    required this.displayName,
    this.description,
    this.version,
    this.inputTokenLimit,
    this.outputTokenLimit,
    required this.supportedGenerationMethods,
  });

  /// Create GeminiModel from JSON
  factory GeminiModel.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final displayName = json['displayName'] as String?;
    final supportedMethods =
        json['supportedGenerationMethods'] as List<dynamic>?;

    if (name == null) {
      throw ArgumentError('Model name is required');
    }
    if (displayName == null) {
      throw ArgumentError('Model display name is required');
    }

    return GeminiModel(
      name: name,
      displayName: displayName,
      description: json['description'] as String?,
      version: json['version'] as String?,
      inputTokenLimit: json['inputTokenLimit'] as int?,
      outputTokenLimit: json['outputTokenLimit'] as int?,
      supportedGenerationMethods: supportedMethods?.cast<String>() ?? [],
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'name': name,
        'displayName': displayName,
        if (description != null) 'description': description,
        if (version != null) 'version': version,
        if (inputTokenLimit != null) 'inputTokenLimit': inputTokenLimit,
        if (outputTokenLimit != null) 'outputTokenLimit': outputTokenLimit,
        'supportedGenerationMethods': supportedGenerationMethods,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiModel &&
        other.name == name &&
        other.displayName == displayName &&
        other.description == description &&
        other.version == version &&
        other.inputTokenLimit == inputTokenLimit &&
        other.outputTokenLimit == outputTokenLimit &&
        _listEquals(
            other.supportedGenerationMethods, supportedGenerationMethods);
  }

  @override
  int get hashCode => Object.hash(
        name,
        displayName,
        description,
        version,
        inputTokenLimit,
        outputTokenLimit,
        supportedGenerationMethods,
      );

  @override
  String toString() => 'GeminiModel('
      'name: $name, '
      'displayName: $displayName, '
      'version: $version)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
