import '../core/platform_imports.dart';
import 'dart:typed_data';

import 'file_types.dart';

/// Represents a file for use with Gemini API multimodal capabilities
///
/// This class provides a convenient way to work with files and their types
/// without having to manually specify MIME types.
class GeminiFile {
  /// The file data as bytes
  final Uint8List data;

  /// The file type (which includes the MIME type)
  final GeminiFileType fileType;

  /// Optional file name for reference
  final String? fileName;

  /// Creates a GeminiFile with the specified data and type
  const GeminiFile({
    required this.data,
    required this.fileType,
    this.fileName,
  });

  /// Creates a GeminiFile from a File object
  ///
  /// Automatically detects the file type from the file extension.
  /// Throws an ArgumentError if the file type is not supported.
  static Future<GeminiFile> fromFile(PlatformFile file) async {
    final bytes = await file.readAsBytes();
    final extension = file.path.split('.').last;
    final fileType = GeminiFileType.fromExtension(extension);

    if (fileType == null) {
      throw ArgumentError('Unsupported file type: .$extension. '
          'Supported types: ${GeminiFileType.allTypes.map((t) => t.name).join(', ')}');
    }

    return GeminiFile(
      data: bytes,
      fileType: fileType,
      fileName: file.path.split('/').last,
    );
  }

  /// Creates a GeminiFile from bytes with explicit file type
  static GeminiFile fromBytes({
    required Uint8List bytes,
    required GeminiFileType fileType,
    String? fileName,
  }) {
    return GeminiFile(
      data: bytes,
      fileType: fileType,
      fileName: fileName,
    );
  }

  /// Creates a GeminiFile from bytes with MIME type string
  ///
  /// Throws an ArgumentError if the MIME type is not supported.
  static GeminiFile fromBytesWithMimeType({
    required Uint8List bytes,
    required String mimeType,
    String? fileName,
  }) {
    final fileType = GeminiFileType.fromMimeType(mimeType);

    if (fileType == null) {
      throw ArgumentError('Unsupported MIME type: $mimeType. '
          'Supported types: ${GeminiFileType.allTypes.map((t) => t.mimeType).join(', ')}');
    }

    return GeminiFile(
      data: bytes,
      fileType: fileType,
      fileName: fileName,
    );
  }

  /// The MIME type of this file
  String get mimeType => fileType.mimeType;

  /// The size of this file in bytes
  int get sizeBytes => data.length;

  /// A human-readable size string (e.g., "1.2 MB")
  String get formattedSize {
    final bytes = sizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Check if this is an image file
  bool get isImage => fileType.isImage;

  /// Check if this is a document file
  bool get isDocument => fileType.isDocument;

  /// Check if this is an audio file
  bool get isAudio => fileType.isAudio;

  /// Check if this is a video file
  bool get isVideo => fileType.isVideo;

  /// Get the category of this file
  GeminiFileCategory get category => fileType.category;

  /// Convert to the tuple format expected by the API
  ({Uint8List data, String mimeType}) toApiFormat() {
    return (data: data, mimeType: mimeType);
  }

  /// Save this file to disk
  Future<void> saveTo(String path) async {
    final file = PlatformFile(path);
    await file.writeAsBytes(data);
  }

  @override
  String toString() {
    final name = fileName ?? 'unnamed';
    return 'GeminiFile($name, ${fileType.description}, $formattedSize)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiFile &&
        other.fileType == fileType &&
        other.fileName == fileName &&
        _listEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(fileType, fileName, data.length);

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extension methods for working with lists of GeminiFile
extension GeminiFileListExtensions on List<GeminiFile> {
  /// Convert all files to API format
  List<({Uint8List data, String mimeType})> toApiFormat() {
    return map((file) => file.toApiFormat()).toList();
  }

  /// Get total size of all files
  int get totalSizeBytes => fold(0, (sum, file) => sum + file.sizeBytes);

  /// Get formatted total size
  String get formattedTotalSize {
    final bytes = totalSizeBytes;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Filter by file category
  List<GeminiFile> whereCategory(GeminiFileCategory category) {
    return where((file) => file.category == category).toList();
  }

  /// Get all images
  List<GeminiFile> get images => whereCategory(GeminiFileCategory.image);

  /// Get all documents
  List<GeminiFile> get documents => whereCategory(GeminiFileCategory.document);

  /// Get all audio files
  List<GeminiFile> get audioFiles => whereCategory(GeminiFileCategory.audio);

  /// Get all video files
  List<GeminiFile> get videoFiles => whereCategory(GeminiFileCategory.video);
}
