import 'dart:typed_data';

/// Utilities for image processing and validation
class ImageUtils {
  /// Maximum file size for images (20MB)
  static const int maxImageSize = 20 * 1024 * 1024;

  /// Maximum image dimensions
  static const int maxImageDimension = 3072;

  /// Supported image MIME types
  static const List<String> supportedMimeTypes = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif',
    'image/bmp',
  ];

  /// Validate image data and MIME type
  static void validateImage(Uint8List data, String mimeType) {
    if (data.isEmpty) {
      throw ArgumentError('Image data cannot be empty');
    }

    if (data.length > maxImageSize) {
      throw ArgumentError(
        'Image size (${data.length} bytes) exceeds maximum allowed size '
        '($maxImageSize bytes)',
      );
    }

    if (!isValidMimeType(mimeType)) {
      throw ArgumentError('Unsupported image MIME type: $mimeType');
    }

    if (!_hasValidImageHeader(data, mimeType)) {
      throw ArgumentError('Invalid image data for MIME type: $mimeType');
    }
  }

  /// Check if MIME type is supported
  static bool isValidMimeType(String mimeType) {
    return supportedMimeTypes.contains(mimeType.toLowerCase());
  }

  /// Get MIME type from image data by examining headers
  static String? detectMimeType(Uint8List data) {
    if (data.length < 2) return null;

    // BMP (only needs 2 bytes)
    if (data[0] == 0x42 && data[1] == 0x4D) {
      return 'image/bmp';
    }

    // JPEG
    if (data[0] == 0xFF && data[1] == 0xD8) {
      return 'image/jpeg';
    }

    // Need at least 4 bytes for the remaining formats
    if (data.length < 4) return null;

    // PNG
    if (data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47) {
      return 'image/png';
    }

    // WebP
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return 'image/webp';
    }

    // GIF
    if (data.length >= 6 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38 &&
        (data[4] == 0x37 || data[4] == 0x39) &&
        data[5] == 0x61) {
      return 'image/gif';
    }

    return null;
  }

  /// Validate image header matches MIME type
  static bool _hasValidImageHeader(Uint8List data, String mimeType) {
    final detectedType = detectMimeType(data);
    if (detectedType == null) return false;

    // Handle jpeg/jpg equivalence
    if ((mimeType == 'image/jpeg' || mimeType == 'image/jpg') &&
        detectedType == 'image/jpeg') {
      return true;
    }

    return detectedType == mimeType;
  }

  /// Calculate optimal dimensions for resizing while maintaining aspect ratio
  static ({int width, int height}) calculateOptimalDimensions(
    int originalWidth,
    int originalHeight, {
    int maxDimension = maxImageDimension,
  }) {
    if (originalWidth <= maxDimension && originalHeight <= maxDimension) {
      return (width: originalWidth, height: originalHeight);
    }

    final aspectRatio = originalWidth / originalHeight;

    int newWidth, newHeight;
    if (originalWidth > originalHeight) {
      newWidth = maxDimension;
      newHeight = (maxDimension / aspectRatio).round();
    } else {
      newHeight = maxDimension;
      newWidth = (maxDimension * aspectRatio).round();
    }

    return (width: newWidth, height: newHeight);
  }

  /// Simple image resizing using nearest neighbor algorithm
  /// Note: This is a basic implementation. For production use,
  /// consider using a proper image processing library
  static Uint8List resizeImage(
    Uint8List imageData,
    int originalWidth,
    int originalHeight,
    int newWidth,
    int newHeight,
  ) {
    // This is a placeholder implementation
    // In a real implementation, you would use an image processing library
    // like the 'image' package for proper resizing

    // For now, we'll return the original data if it's within limits
    if (imageData.length <= maxImageSize) {
      return imageData;
    }

    // If the image is too large, we need to compress it
    // This is a simplified approach - in practice you'd use proper compression
    throw UnsupportedError(
      'Image resizing not implemented. Use an image processing library '
      'like the "image" package for proper resizing functionality.',
    );
  }

  /// Estimate image quality based on file size and dimensions
  static double estimateQuality(Uint8List data, int width, int height) {
    final bytesPerPixel = data.length / (width * height);

    // Rough quality estimation based on bytes per pixel
    if (bytesPerPixel > 3.0) return 1.0; // High quality
    if (bytesPerPixel > 1.5) return 0.8; // Good quality
    if (bytesPerPixel > 0.8) return 0.6; // Medium quality
    if (bytesPerPixel > 0.4) return 0.4; // Low quality
    return 0.2; // Very low quality
  }

  /// Format file size for human-readable display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
