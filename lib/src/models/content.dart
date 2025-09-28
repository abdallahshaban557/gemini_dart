import 'dart:convert';
import 'dart:typed_data';

/// Abstract base class for all content types that can be sent to Gemini API
abstract class Content {
  /// The type identifier for this content
  String get type;

  /// Convert this content to JSON representation
  Map<String, dynamic> toJson();

  /// Create Content from JSON representation
  static Content fromJson(Map<String, dynamic> json) {
    // Handle API response format with 'parts'
    if (json.containsKey('parts')) {
      final parts = json['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        // Check if we have multiple parts with different types
        String? text;
        List<ImageContent> images = [];

        for (final part in parts) {
          final partMap = part as Map<String, dynamic>;
          if (partMap.containsKey('text')) {
            text = partMap['text'] as String;
          } else if (partMap.containsKey('inlineData')) {
            final inlineData = partMap['inlineData'] as Map<String, dynamic>;
            final imageData = inlineData['data'] as String;
            final mimeType = inlineData['mimeType'] as String;

            // Convert base64 to bytes
            final bytes = base64Decode(imageData);
            images.add(ImageContent(bytes, mimeType));
          }
        }

        // If we have both text and images, return MultiPartContent
        if (text != null && images.isNotEmpty) {
          return MultiPartContent(text: text, images: images);
        }
        // If we only have text, return TextContent
        else if (text != null) {
          return TextContent(text);
        }
        // If we only have images, return the first image
        else if (images.isNotEmpty) {
          return images.first;
        }

        // Fallback to first part as text
        final firstPart = parts.first as Map<String, dynamic>;
        if (firstPart.containsKey('text')) {
          return TextContent(firstPart['text'] as String);
        }
      }
    }

    // Handle empty content (e.g., when response is truncated due to token limits)
    if (!json.containsKey('parts') && !json.containsKey('type')) {
      // Return empty text content for truncated responses
      return TextContent('');
    }

    // Handle our internal format with 'type'
    final type = json['type'] as String?;
    switch (type) {
      case 'text':
        return TextContent.fromJson(json);
      case 'image':
        return ImageContent.fromJson(json);
      case 'video':
        return VideoContent.fromJson(json);
      case 'multipart':
        return MultiPartContent.fromJson(json);
      default:
        throw ArgumentError('Unknown content type: $type');
    }
  }
}

/// Text content for sending text prompts to Gemini
class TextContent extends Content {
  /// The text content
  final String text;

  /// Creates a new TextContent with the given text
  /// Empty text is allowed for truncated responses
  TextContent(this.text);

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
      };

  /// Create TextContent from JSON
  factory TextContent.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String?;
    if (text == null) {
      throw ArgumentError('Text field is required for TextContent');
    }
    return TextContent(text);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is TextContent && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextContent(text: $text)';
}

/// Image content for sending images to Gemini
class ImageContent extends Content {
  /// Create ImageContent from JSON
  factory ImageContent.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Uint8List?;
    final mimeType = json['mimeType'] as String?;

    if (data == null) {
      throw ArgumentError('Data field is required for ImageContent');
    }
    if (mimeType == null) {
      throw ArgumentError('MimeType field is required for ImageContent');
    }

    return ImageContent(data, mimeType);
  }

  /// Creates a new ImageContent with the given data and MIME type
  ImageContent(this.data, this.mimeType) {
    if (data.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }
    if (!_isValidImageMimeType(mimeType)) {
      throw ArgumentError('Invalid image MIME type: $mimeType');
    }
  }

  /// The image data as bytes
  final Uint8List data;

  /// The MIME type of the image (e.g., 'image/jpeg', 'image/png')
  final String mimeType;

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'data': data,
        'mimeType': mimeType,
      };

  /// Check if the MIME type is valid for images
  static bool _isValidImageMimeType(String mimeType) {
    const validTypes = [
      'image/jpeg',
      'image/jpg',
      'image/png',
      'image/webp',
      'image/gif',
      'image/bmp',
    ];
    return validTypes.contains(mimeType.toLowerCase());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ImageContent &&
        other.mimeType == mimeType &&
        _listEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(data.length, mimeType);

  @override
  String toString() =>
      'ImageContent(mimeType: $mimeType, size: ${data.length} bytes)';

  /// Helper method to compare Uint8List
  static bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// Video content for sending videos to Gemini
class VideoContent extends Content {
  /// Create VideoContent from JSON
  factory VideoContent.fromJson(Map<String, dynamic> json) {
    final fileUri = json['fileUri'] as String?;
    final mimeType = json['mimeType'] as String?;

    if (fileUri == null) {
      throw ArgumentError('FileUri field is required for VideoContent');
    }
    if (mimeType == null) {
      throw ArgumentError('MimeType field is required for VideoContent');
    }

    return VideoContent(fileUri, mimeType);
  }

  /// The URI of the uploaded video file
  final String fileUri;

  /// The MIME type of the video (e.g., 'video/mp4', 'video/mov')
  final String mimeType;

  /// Creates a new VideoContent with the given file URI and MIME type
  VideoContent(this.fileUri, this.mimeType) {
    if (fileUri.isEmpty) {
      throw ArgumentError('File URI cannot be empty');
    }
    if (!_isValidVideoMimeType(mimeType)) {
      throw ArgumentError('Invalid video MIME type: $mimeType');
    }
  }

  @override
  String get type => 'video';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'fileUri': fileUri,
        'mimeType': mimeType,
      };

  /// Check if the MIME type is valid for videos
  static bool _isValidVideoMimeType(String mimeType) {
    const validTypes = [
      'video/mp4',
      'video/mpeg',
      'video/mov',
      'video/avi',
      'video/x-flv',
      'video/mpg',
      'video/webm',
      'video/wmv',
      'video/3gpp',
    ];
    return validTypes.contains(mimeType.toLowerCase());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is VideoContent &&
        other.fileUri == fileUri &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(fileUri, mimeType);

  @override
  String toString() => 'VideoContent(fileUri: $fileUri, mimeType: $mimeType)';
}

/// Multi-part content containing both text and image data
/// Used for responses from image generation that include both description and generated images
class MultiPartContent extends Content {
  /// The text description
  final String text;

  /// The generated images
  final List<ImageContent> images;

  /// Creates a new MultiPartContent with text and images
  MultiPartContent({
    required this.text,
    required this.images,
  }) {
    if (images.isEmpty) {
      throw ArgumentError('Images list cannot be empty for MultiPartContent');
    }
  }

  @override
  String get type => 'multipart';

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'text': text,
        'images': images.map((img) => img.toJson()).toList(),
      };

  /// Create MultiPartContent from JSON
  factory MultiPartContent.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String?;
    final imagesJson = json['images'] as List<dynamic>?;

    if (text == null) {
      throw ArgumentError('Text field is required for MultiPartContent');
    }
    if (imagesJson == null) {
      throw ArgumentError('Images field is required for MultiPartContent');
    }

    final images = imagesJson
        .map((img) => ImageContent.fromJson(img as Map<String, dynamic>))
        .toList();

    return MultiPartContent(text: text, images: images);
  }

  /// Get the first generated image
  ImageContent get firstImage => images.first;

  /// Get all image data as bytes
  List<Uint8List> get imageDataList => images.map((img) => img.data).toList();

  /// Get all image MIME types
  List<String> get imageMimeTypes => images.map((img) => img.mimeType).toList();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MultiPartContent &&
        other.text == text &&
        _listEquals(other.images, images);
  }

  @override
  int get hashCode => Object.hash(text, images.length);

  @override
  String toString() =>
      'MultiPartContent(text: $text, images: ${images.length})';

  /// Helper method to compare lists
  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
