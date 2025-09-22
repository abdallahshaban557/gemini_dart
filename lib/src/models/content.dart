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
        final firstPart = parts.first as Map<String, dynamic>;
        if (firstPart.containsKey('text')) {
          return TextContent(firstPart['text'] as String);
        }
        // Handle other part types as needed
      }
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
  TextContent(this.text) {
    if (text.isEmpty) {
      throw ArgumentError('Text content cannot be empty');
    }
  }

  @override
  String get type => 'text';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
    };
  }

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
    if (identical(this, other)) return true;
    return other is TextContent && other.text == text;
  }

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextContent(text: $text)';
}

/// Image content for sending images to Gemini
class ImageContent extends Content {
  /// The image data as bytes
  final Uint8List data;

  /// The MIME type of the image (e.g., 'image/jpeg', 'image/png')
  final String mimeType;

  /// Creates a new ImageContent with the given data and MIME type
  ImageContent(this.data, this.mimeType) {
    if (data.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }
    if (!_isValidImageMimeType(mimeType)) {
      throw ArgumentError('Invalid image MIME type: $mimeType');
    }
  }

  @override
  String get type => 'image';

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'mimeType': mimeType,
    };
  }

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
    if (identical(this, other)) return true;
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
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Video content for sending videos to Gemini
class VideoContent extends Content {
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
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'fileUri': fileUri,
      'mimeType': mimeType,
    };
  }

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
    if (identical(this, other)) return true;
    return other is VideoContent &&
        other.fileUri == fileUri &&
        other.mimeType == mimeType;
  }

  @override
  int get hashCode => Object.hash(fileUri, mimeType);

  @override
  String toString() => 'VideoContent(fileUri: $fileUri, mimeType: $mimeType)';
}
