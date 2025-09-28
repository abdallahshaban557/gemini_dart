/// Supported file types for multimodal content generation
///
/// This enum provides type-safe access to all supported MIME types
/// for use with the Gemini API's multimodal capabilities.
enum GeminiFileType {
  // Image formats
  /// JPEG image format
  jpeg('image/jpeg'),

  /// JPG image format (alias for JPEG)
  jpg('image/jpg'),

  /// PNG image format
  png('image/png'),

  /// WebP image format
  webp('image/webp'),

  /// GIF image format
  gif('image/gif'),

  // Document formats
  /// PDF document format
  pdf('application/pdf'),

  // Audio formats
  /// MP3 audio format
  mp3('audio/mp3'),

  /// MPEG audio format
  mpeg('audio/mpeg'),

  /// WAV audio format
  wav('audio/wav'),

  /// FLAC audio format
  flac('audio/flac'),

  // Video formats
  /// MP4 video format
  mp4('video/mp4'),

  /// MOV video format (QuickTime)
  mov('video/mov'),

  /// AVI video format
  avi('video/avi'),

  /// WebM video format
  webm('video/webm'),

  /// QuickTime video format
  quicktime('video/quicktime');

  /// Creates a GeminiFileType with the associated MIME type
  const GeminiFileType(this.mimeType);

  /// The MIME type string for this file type
  final String mimeType;

  /// Get all image file types
  static List<GeminiFileType> get imageTypes => [
        jpeg,
        jpg,
        png,
        webp,
        gif,
      ];

  /// Get all document file types
  static List<GeminiFileType> get documentTypes => [
        pdf,
      ];

  /// Get all audio file types
  static List<GeminiFileType> get audioTypes => [
        mp3,
        mpeg,
        wav,
        flac,
      ];

  /// Get all video file types
  static List<GeminiFileType> get videoTypes => [
        mp4,
        mov,
        avi,
        webm,
        quicktime,
      ];

  /// Get all supported file types
  static List<GeminiFileType> get allTypes => [
        ...imageTypes,
        ...documentTypes,
        ...audioTypes,
        ...videoTypes,
      ];

  /// Check if this file type is an image
  bool get isImage => imageTypes.contains(this);

  /// Check if this file type is a document
  bool get isDocument => documentTypes.contains(this);

  /// Check if this file type is audio
  bool get isAudio => audioTypes.contains(this);

  /// Check if this file type is video
  bool get isVideo => videoTypes.contains(this);

  /// Get the category of this file type
  GeminiFileCategory get category {
    if (isImage) return GeminiFileCategory.image;
    if (isDocument) return GeminiFileCategory.document;
    if (isAudio) return GeminiFileCategory.audio;
    if (isVideo) return GeminiFileCategory.video;
    throw StateError('Unknown file category for $this');
  }

  /// Create a GeminiFileType from a MIME type string
  ///
  /// Returns null if the MIME type is not supported
  static GeminiFileType? fromMimeType(String mimeType) {
    for (final type in allTypes) {
      if (type.mimeType.toLowerCase() == mimeType.toLowerCase()) {
        return type;
      }
    }
    return null;
  }

  /// Create a GeminiFileType from a file extension
  ///
  /// Returns null if the extension is not supported
  static GeminiFileType? fromExtension(String extension) {
    final ext = extension.toLowerCase().replaceFirst('.', '');

    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
        return jpeg;
      case 'png':
        return png;
      case 'webp':
        return webp;
      case 'gif':
        return gif;

      // Documents
      case 'pdf':
        return pdf;

      // Audio
      case 'mp3':
        return mp3;
      case 'wav':
        return wav;
      case 'flac':
        return flac;

      // Video
      case 'mp4':
        return mp4;
      case 'mov':
        return mov;
      case 'avi':
        return avi;
      case 'webm':
        return webm;

      default:
        return null;
    }
  }

  /// Get a user-friendly description of this file type
  String get description {
    switch (this) {
      // Images
      case jpeg:
      case jpg:
        return 'JPEG Image';
      case png:
        return 'PNG Image';
      case webp:
        return 'WebP Image';
      case gif:
        return 'GIF Image';

      // Documents
      case pdf:
        return 'PDF Document';

      // Audio
      case mp3:
        return 'MP3 Audio';
      case mpeg:
        return 'MPEG Audio';
      case wav:
        return 'WAV Audio';
      case flac:
        return 'FLAC Audio';

      // Video
      case mp4:
        return 'MP4 Video';
      case mov:
        return 'QuickTime Video';
      case avi:
        return 'AVI Video';
      case webm:
        return 'WebM Video';
      case quicktime:
        return 'QuickTime Video';
    }
  }

  @override
  String toString() => mimeType;
}

/// Categories of supported file types
enum GeminiFileCategory {
  /// Image files (JPEG, PNG, WebP, GIF)
  image('Images'),

  /// Document files (PDF)
  document('Documents'),

  /// Audio files (MP3, WAV, FLAC)
  audio('Audio'),

  /// Video files (MP4, MOV, AVI, WebM)
  video('Video');

  /// Creates a GeminiFileCategory with a display name
  const GeminiFileCategory(this.displayName);

  /// The display name for this category
  final String displayName;

  /// Get all file types in this category
  List<GeminiFileType> get fileTypes {
    switch (this) {
      case image:
        return GeminiFileType.imageTypes;
      case document:
        return GeminiFileType.documentTypes;
      case audio:
        return GeminiFileType.audioTypes;
      case video:
        return GeminiFileType.videoTypes;
    }
  }
}
