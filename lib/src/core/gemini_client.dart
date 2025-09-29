import 'platform_imports.dart';
import 'dart:typed_data';

import '../handlers/conversation_context.dart';
import '../handlers/image_handler.dart';
import '../handlers/multimodal_handler.dart';
import '../handlers/text_handler.dart';
import '../models/gemini_config.dart';
import '../models/gemini_file.dart';
import '../models/gemini_models_simple.dart';
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
  /// Creates a new GeminiClient with optional configuration and model
  ///
  /// Example:
  /// ```dart
  /// final client = GeminiClient(model: GeminiModels.gemini15Flash);
  /// await client.initialize(apiKey);
  /// final response = await client.generateText(prompt: "Hello");
  /// ```
  GeminiClient({
    GeminiModel? model,
    String? modelName, // Legacy support
    GeminiConfig? config,
    RetryConfig? retryConfig,
  })  : _config = config ?? const GeminiConfig(),
        _selectedModel = _resolveModel(model, modelName) {
    _initializeServices(retryConfig);
  }

  HttpService? _httpService;
  AuthenticationHandler? _auth;
  TextHandler? _textHandler;
  ImageHandler? _imageHandler;
  MultiModalHandler? _multiModalHandler;

  GeminiConfig _config;
  GeminiModel? _selectedModel;
  bool _initialized = false;

  /// Resolve the model from either GeminiModel or model name
  static GeminiModel? _resolveModel(GeminiModel? model, String? modelName) {
    if (model != null) return model;
    if (modelName != null) return GeminiModels.findByName(modelName);
    return null;
  }

  /// Initialize all internal services
  void _initializeServices(RetryConfig? retryConfig) {
    _auth = AuthenticationHandler();

    // Use the model's API version if available, otherwise use config default
    final apiVersion = _selectedModel?.apiVersion ?? _config.apiVersion;
    final configWithApiVersion = _config.copyWith(apiVersion: apiVersion);

    _httpService = HttpService(
      auth: _auth!,
      config: configWithApiVersion,
      retryConfig: retryConfig,
    );

    // Pass model name to handlers
    final modelName = _selectedModel?.name ?? 'gemini-2.5-flash';
    _textHandler = TextHandler(httpService: _httpService!, model: modelName);
    _imageHandler = ImageHandler(httpService: _httpService!, model: modelName);
    _imageHandler = ImageHandler(httpService: _httpService!, model: modelName);
    _multiModalHandler = MultiModalHandler(httpService: _httpService!);
  }

  /// Initialize the client with an API key
  ///
  /// This must be called before using any generation methods.
  /// The API key will be validated and stored for subsequent requests.
  Future<void> initialize({
    required String apiKey,
    GeminiConfig? config,
  }) async {
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

  /// Generate text from a simple text prompt
  Future<GeminiResponse> generateText({
    required String prompt,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();
    _validateModelCapability(ModelCapability.textGeneration, 'generateText');

    return _textHandler!
        .generateText(prompt: prompt, config: config, context: context);
  }

  /// Generate streaming text from a text prompt
  ///
  /// Returns a stream of partial responses for real-time text generation.
  Stream<GeminiResponse> generateTextStream({
    required String prompt,
    GenerationConfig? config,
  }) async* {
    _ensureInitialized();
    _validateModelCapability(
        ModelCapability.textGeneration, 'generateTextStream');
    yield* _textHandler!.generateTextStream(prompt: prompt, config: config);
    yield* _textHandler!.generateTextStream(prompt: prompt, config: config);
  }

  /// Generate an image from a text prompt with optional input files
  ///
  /// This method uses Gemini's image generation capabilities to create images
  /// from text descriptions, optionally using input files as reference.
  ///
  /// Examples:
  /// ```dart
  /// // Text-only image generation
  /// final response = await client.generateImage(prompt: 'A sunset over mountains');
  ///
  /// // Using GeminiFile objects (recommended)
  /// final imageFile = await GeminiFile.fromFile(PlatformFile('image.png'));
  /// final response = await client.generateImage(
  ///   prompt: 'Make this image more colorful',
  ///   geminiFiles: [imageFile], // Direct usage - no toApiFormat needed!
  /// );
  ///
  /// // Multiple file types
  /// final files = [
  ///   await GeminiFile.fromFile(PlatformFile('document.pdf')),
  ///   await GeminiFile.fromFile(File('audio.mp3')),
  /// ];
  /// final response = await client.generateImage(
  ///   prompt: 'Create artwork combining these elements',
  ///   geminiFiles: files, // Clean and simple!
  /// );
  ///
  /// // Legacy raw format (still supported)
  /// final response = await client.generateImage(
  ///   prompt: 'Transform this',
  ///   files: [(data: imageBytes, mimeType: 'image/png')],
  /// );
  /// ```
  Future<GeminiResponse> generateImage({
    required String prompt,
    List<GeminiFile>? geminiFiles,
    List<({Uint8List data, String mimeType})>? files,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();
    _validateModelCapability(ModelCapability.imageGeneration, 'generateImage');

    return _imageHandler!.generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      files: files,
      config: config,
      context: context,
    );
    _validateModelCapability(ModelCapability.imageGeneration, 'generateImage');

    return _imageHandler!.generateImage(
      prompt: prompt,
      geminiFiles: geminiFiles,
      files: files,
      config: config,
      context: context,
    );
  }

  /// Create a multi-modal prompt with text and files
  ///
  /// This is a convenience method for creating complex multi-modal requests.
  ///
  /// Examples:
  /// ```dart
  /// // Text-only
  /// final response = await client.createMultiModalPrompt(
  ///   text: 'Explain quantum physics',
  /// );
  ///
  /// // Text with files
  /// final imageFile = await GeminiFile.fromFile(PlatformFile('image.png'));
  /// final videoFile = await GeminiFile.fromFile(File('video.mp4'));
  /// final response = await client.createMultiModalPrompt(
  ///   text: 'Analyze these media files',
  ///   files: [imageFile, videoFile],
  /// );
  ///
  /// // Multiple file types
  /// final files = [
  ///   await GeminiFile.fromFile(PlatformFile('document.pdf')),
  ///   await GeminiFile.fromFile(File('audio.mp3')),
  ///   await GeminiFile.fromFile(File('image.jpg')),
  /// ];
  /// final response = await client.createMultiModalPrompt(
  ///   text: 'Analyze all these files together',
  ///   files: files,
  /// );
  /// ```
  Future<GeminiResponse> createMultiModalPrompt({
    String? text,
    List<GeminiFile>? files,
    GenerationConfig? config,
    ConversationContext? context,
  }) async {
    _ensureInitialized();
    _validateModelCapability(
        ModelCapability.multiModalInput, 'createMultiModalPrompt');

    return _multiModalHandler!.createPrompt(
      text: text,
      files: files,
      config: config,
      context: context,
    );
  }

  /// Upload a file for use in video content generation
  ///
  /// This method uploads large files (typically videos) to the Gemini API
  /// and returns a file URI that can be used in VideoContent objects.
  Future<FileUploadResponse> uploadFile({
    required PlatformFile file,
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

  /// Get available predefined models
  ///
  /// Returns a list of predefined models with their API versions and capabilities.
  List<GeminiModel> getModels() {
    return GeminiModels.allModels;
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

  /// Get the currently selected model
  GeminiModel? get selectedModel => _selectedModel;

  /// Get the currently selected model name
  String? get selectedModelName => _selectedModel?.name;

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

  /// Validate that the current model has the required capability
  void _validateModelCapability(ModelCapability capability, String methodName) {
    final model = _selectedModel;
    if (model == null) {
      // If no model is selected, we'll use the default which should support the capability
      return;
    }

    if (!model.hasCapability(capability)) {
      final supportedModels = GeminiModels.getModelsWithCapability(capability)
          .map((m) => m.name)
          .join(', ');

      throw GeminiValidationException(
        'Model ${model.name} does not support ${capability.description}. '
        'Use a model with this capability: $supportedModels',
        {'model': '${capability.description} not supported by this model'},
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
