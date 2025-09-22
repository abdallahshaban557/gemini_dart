import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:gemini_dart/src/utils/image_utils.dart';

void main() {
  group('ImageUtils', () {
    group('validateImage', () {
      test('should accept valid JPEG image', () {
        // JPEG header: FF D8
        final jpegData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

        expect(
          () => ImageUtils.validateImage(jpegData, 'image/jpeg'),
          returnsNormally,
        );
      });

      test('should accept valid PNG image', () {
        // PNG header: 89 50 4E 47
        final pngData = Uint8List.fromList(
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        expect(
          () => ImageUtils.validateImage(pngData, 'image/png'),
          returnsNormally,
        );
      });

      test('should throw on empty image data', () {
        final emptyData = Uint8List(0);

        expect(
          () => ImageUtils.validateImage(emptyData, 'image/jpeg'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on unsupported MIME type', () {
        final jpegData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);

        expect(
          () => ImageUtils.validateImage(jpegData, 'image/tiff'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on mismatched header and MIME type', () {
        // PNG header with JPEG MIME type
        final pngData = Uint8List.fromList(
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);

        expect(
          () => ImageUtils.validateImage(pngData, 'image/jpeg'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw on oversized image', () {
        // Create data larger than max size
        final oversizedData = Uint8List(ImageUtils.maxImageSize + 1);
        // Set JPEG header
        oversizedData[0] = 0xFF;
        oversizedData[1] = 0xD8;

        expect(
          () => ImageUtils.validateImage(oversizedData, 'image/jpeg'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('isValidMimeType', () {
      test('should return true for supported MIME types', () {
        const supportedTypes = [
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/webp',
          'image/gif',
          'image/bmp',
        ];

        for (final type in supportedTypes) {
          expect(ImageUtils.isValidMimeType(type), isTrue);
        }
      });

      test('should return false for unsupported MIME types', () {
        const unsupportedTypes = [
          'image/tiff',
          'image/svg+xml',
          'text/plain',
          'application/json',
        ];

        for (final type in unsupportedTypes) {
          expect(ImageUtils.isValidMimeType(type), isFalse);
        }
      });

      test('should be case insensitive', () {
        expect(ImageUtils.isValidMimeType('IMAGE/JPEG'), isTrue);
        expect(ImageUtils.isValidMimeType('Image/Png'), isTrue);
      });
    });

    group('detectMimeType', () {
      test('should detect JPEG format', () {
        final jpegData = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
        expect(ImageUtils.detectMimeType(jpegData), equals('image/jpeg'));
      });

      test('should detect PNG format', () {
        final pngData = Uint8List.fromList(
            [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        expect(ImageUtils.detectMimeType(pngData), equals('image/png'));
      });

      test('should detect WebP format', () {
        final webpData = Uint8List.fromList([
          0x52, 0x49, 0x46, 0x46, // RIFF
          0x00, 0x00, 0x00, 0x00, // File size (placeholder)
          0x57, 0x45, 0x42, 0x50, // WEBP
        ]);
        expect(ImageUtils.detectMimeType(webpData), equals('image/webp'));
      });

      test('should detect GIF format', () {
        final gifData = Uint8List.fromList([
          0x47, 0x49, 0x46, 0x38, 0x37, 0x61 // GIF87a
        ]);
        expect(ImageUtils.detectMimeType(gifData), equals('image/gif'));
      });

      test('should detect BMP format', () {
        final bmpData = Uint8List.fromList([0x42, 0x4D]);
        expect(ImageUtils.detectMimeType(bmpData), equals('image/bmp'));
      });

      test('should return null for unknown format', () {
        final unknownData = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
        expect(ImageUtils.detectMimeType(unknownData), isNull);
      });

      test('should return null for insufficient data', () {
        final shortData = Uint8List.fromList([0xFF]);
        expect(ImageUtils.detectMimeType(shortData), isNull);
      });
    });

    group('calculateOptimalDimensions', () {
      test('should return original dimensions if within limits', () {
        final result = ImageUtils.calculateOptimalDimensions(1024, 768);
        expect(result.width, equals(1024));
        expect(result.height, equals(768));
      });

      test('should scale down width-dominant image', () {
        final result = ImageUtils.calculateOptimalDimensions(4000, 2000);
        expect(result.width, equals(ImageUtils.maxImageDimension));
        expect(result.height, equals(1536)); // 3072 / 2
      });

      test('should scale down height-dominant image', () {
        final result = ImageUtils.calculateOptimalDimensions(2000, 4000);
        expect(result.width, equals(1536)); // 3072 / 2
        expect(result.height, equals(ImageUtils.maxImageDimension));
      });

      test('should handle square images', () {
        final result = ImageUtils.calculateOptimalDimensions(4000, 4000);
        expect(result.width, equals(ImageUtils.maxImageDimension));
        expect(result.height, equals(ImageUtils.maxImageDimension));
      });

      test('should respect custom max dimension', () {
        final result = ImageUtils.calculateOptimalDimensions(
          2000,
          1000,
          maxDimension: 1000,
        );
        expect(result.width, equals(1000));
        expect(result.height, equals(500));
      });
    });

    group('estimateQuality', () {
      test('should return high quality for high bytes per pixel', () {
        final data = Uint8List(1000 * 1000 * 4); // 4 bytes per pixel
        final quality = ImageUtils.estimateQuality(data, 1000, 1000);
        expect(quality, equals(1.0));
      });

      test('should return low quality for low bytes per pixel', () {
        final data = Uint8List(1000 * 1000 ~/ 3); // ~0.33 bytes per pixel
        final quality = ImageUtils.estimateQuality(data, 1000, 1000);
        expect(quality, equals(0.2));
      });

      test('should return medium quality for medium bytes per pixel', () {
        final data = Uint8List(1000 * 1000); // 1 byte per pixel
        final quality = ImageUtils.estimateQuality(data, 1000, 1000);
        expect(quality, equals(0.6));
      });
    });

    group('formatFileSize', () {
      test('should format bytes correctly', () {
        expect(ImageUtils.formatFileSize(512), equals('512 B'));
      });

      test('should format kilobytes correctly', () {
        expect(ImageUtils.formatFileSize(1536), equals('1.5 KB'));
      });

      test('should format megabytes correctly', () {
        expect(ImageUtils.formatFileSize(2 * 1024 * 1024), equals('2.0 MB'));
      });

      test('should format large sizes correctly', () {
        expect(ImageUtils.formatFileSize(1536 * 1024), equals('1.5 MB'));
      });
    });

    group('resizeImage', () {
      test('should throw UnsupportedError for now', () {
        final data = Uint8List(ImageUtils.maxImageSize + 1);

        expect(
          () => ImageUtils.resizeImage(data, 1000, 1000, 500, 500),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('should return original data if within size limits', () {
        final data = Uint8List(1000);
        final result = ImageUtils.resizeImage(data, 1000, 1000, 500, 500);
        expect(result, equals(data));
      });
    });
  });
}
