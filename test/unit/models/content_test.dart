import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:gemini_dart/src/models/content.dart';

void main() {
  group('TextContent', () {
    test('should create TextContent with valid text', () {
      const text = 'Hello, Gemini!';
      final content = TextContent(text);

      expect(content.text, equals(text));
      expect(content.type, equals('text'));
    });

    test('should throw ArgumentError for empty text', () {
      expect(() => TextContent(''), throwsArgumentError);
    });

    test('should serialize to JSON correctly', () {
      const text = 'Test message';
      final content = TextContent(text);
      final json = content.toJson();

      expect(
          json,
          equals({
            'type': 'text',
            'text': text,
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'text',
        'text': 'Test message',
      };
      final content = TextContent.fromJson(json);

      expect(content.text, equals('Test message'));
      expect(content.type, equals('text'));
    });

    test('should throw ArgumentError when deserializing without text field',
        () {
      final json = {'type': 'text'};
      expect(() => TextContent.fromJson(json), throwsArgumentError);
    });

    test('should implement equality correctly', () {
      final content1 = TextContent('Hello');
      final content2 = TextContent('Hello');
      final content3 = TextContent('World');

      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
    });

    test('should implement hashCode correctly', () {
      final content1 = TextContent('Hello');
      final content2 = TextContent('Hello');

      expect(content1.hashCode, equals(content2.hashCode));
    });

    test('should implement toString correctly', () {
      final content = TextContent('Hello');
      expect(content.toString(), equals('TextContent(text: Hello)'));
    });
  });

  group('ImageContent', () {
    late Uint8List testImageData;

    setUp(() {
      testImageData = Uint8List.fromList([1, 2, 3, 4, 5]);
    });

    test('should create ImageContent with valid data and MIME type', () {
      const mimeType = 'image/jpeg';
      final content = ImageContent(testImageData, mimeType);

      expect(content.data, equals(testImageData));
      expect(content.mimeType, equals(mimeType));
      expect(content.type, equals('image'));
    });

    test('should throw ArgumentError for empty data', () {
      final emptyData = Uint8List(0);
      expect(() => ImageContent(emptyData, 'image/jpeg'), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid MIME type', () {
      expect(
          () => ImageContent(testImageData, 'text/plain'), throwsArgumentError);
    });

    test('should accept valid image MIME types', () {
      final validTypes = [
        'image/jpeg',
        'image/jpg',
        'image/png',
        'image/webp',
        'image/gif',
        'image/bmp',
      ];

      for (final mimeType in validTypes) {
        expect(() => ImageContent(testImageData, mimeType), returnsNormally);
      }
    });

    test('should serialize to JSON correctly', () {
      const mimeType = 'image/png';
      final content = ImageContent(testImageData, mimeType);
      final json = content.toJson();

      expect(
          json,
          equals({
            'type': 'image',
            'data': testImageData,
            'mimeType': mimeType,
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'image',
        'data': testImageData,
        'mimeType': 'image/jpeg',
      };
      final content = ImageContent.fromJson(json);

      expect(content.data, equals(testImageData));
      expect(content.mimeType, equals('image/jpeg'));
      expect(content.type, equals('image'));
    });

    test(
        'should throw ArgumentError when deserializing without required fields',
        () {
      expect(
          () => ImageContent.fromJson({'type': 'image'}), throwsArgumentError);
      expect(
          () => ImageContent.fromJson({'type': 'image', 'data': testImageData}),
          throwsArgumentError);
      expect(
          () => ImageContent.fromJson(
              {'type': 'image', 'mimeType': 'image/jpeg'}),
          throwsArgumentError);
    });

    test('should implement equality correctly', () {
      final content1 = ImageContent(testImageData, 'image/jpeg');
      final content2 = ImageContent(testImageData, 'image/jpeg');
      final content3 =
          ImageContent(Uint8List.fromList([6, 7, 8]), 'image/jpeg');
      final content4 = ImageContent(testImageData, 'image/png');

      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
      expect(content1, isNot(equals(content4)));
    });

    test('should implement toString correctly', () {
      final content = ImageContent(testImageData, 'image/jpeg');
      expect(content.toString(),
          equals('ImageContent(mimeType: image/jpeg, size: 5 bytes)'));
    });
  });

  group('VideoContent', () {
    test('should create VideoContent with valid URI and MIME type', () {
      const fileUri = 'gs://bucket/video.mp4';
      const mimeType = 'video/mp4';
      final content = VideoContent(fileUri, mimeType);

      expect(content.fileUri, equals(fileUri));
      expect(content.mimeType, equals(mimeType));
      expect(content.type, equals('video'));
    });

    test('should throw ArgumentError for empty file URI', () {
      expect(() => VideoContent('', 'video/mp4'), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid MIME type', () {
      expect(() => VideoContent('gs://bucket/video.mp4', 'text/plain'),
          throwsArgumentError);
    });

    test('should accept valid video MIME types', () {
      const fileUri = 'gs://bucket/video';
      final validTypes = [
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

      for (final mimeType in validTypes) {
        expect(() => VideoContent(fileUri, mimeType), returnsNormally);
      }
    });

    test('should serialize to JSON correctly', () {
      const fileUri = 'gs://bucket/video.mp4';
      const mimeType = 'video/mp4';
      final content = VideoContent(fileUri, mimeType);
      final json = content.toJson();

      expect(
          json,
          equals({
            'type': 'video',
            'fileUri': fileUri,
            'mimeType': mimeType,
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'video',
        'fileUri': 'gs://bucket/video.mp4',
        'mimeType': 'video/mp4',
      };
      final content = VideoContent.fromJson(json);

      expect(content.fileUri, equals('gs://bucket/video.mp4'));
      expect(content.mimeType, equals('video/mp4'));
      expect(content.type, equals('video'));
    });

    test(
        'should throw ArgumentError when deserializing without required fields',
        () {
      expect(
          () => VideoContent.fromJson({'type': 'video'}), throwsArgumentError);
      expect(
          () => VideoContent.fromJson(
              {'type': 'video', 'fileUri': 'gs://bucket/video.mp4'}),
          throwsArgumentError);
      expect(
          () =>
              VideoContent.fromJson({'type': 'video', 'mimeType': 'video/mp4'}),
          throwsArgumentError);
    });

    test('should implement equality correctly', () {
      final content1 = VideoContent('gs://bucket/video1.mp4', 'video/mp4');
      final content2 = VideoContent('gs://bucket/video1.mp4', 'video/mp4');
      final content3 = VideoContent('gs://bucket/video2.mp4', 'video/mp4');
      final content4 = VideoContent('gs://bucket/video1.mp4', 'video/mov');

      expect(content1, equals(content2));
      expect(content1, isNot(equals(content3)));
      expect(content1, isNot(equals(content4)));
    });

    test('should implement toString correctly', () {
      final content = VideoContent('gs://bucket/video.mp4', 'video/mp4');
      expect(
          content.toString(),
          equals(
              'VideoContent(fileUri: gs://bucket/video.mp4, mimeType: video/mp4)'));
    });
  });

  group('Content.fromJson', () {
    test('should create TextContent from JSON', () {
      final json = {'type': 'text', 'text': 'Hello'};
      final content = Content.fromJson(json);

      expect(content, isA<TextContent>());
      expect((content as TextContent).text, equals('Hello'));
    });

    test('should create ImageContent from JSON', () {
      final data = Uint8List.fromList([1, 2, 3]);
      final json = {'type': 'image', 'data': data, 'mimeType': 'image/jpeg'};
      final content = Content.fromJson(json);

      expect(content, isA<ImageContent>());
      expect((content as ImageContent).data, equals(data));
    });

    test('should create VideoContent from JSON', () {
      final json = {
        'type': 'video',
        'fileUri': 'gs://bucket/video.mp4',
        'mimeType': 'video/mp4'
      };
      final content = Content.fromJson(json);

      expect(content, isA<VideoContent>());
      expect(
          (content as VideoContent).fileUri, equals('gs://bucket/video.mp4'));
    });

    test('should throw ArgumentError for unknown content type', () {
      final json = {'type': 'unknown'};
      expect(() => Content.fromJson(json), throwsArgumentError);
    });

    test('should throw ArgumentError for missing type field', () {
      final json = {'text': 'Hello'};
      expect(() => Content.fromJson(json), throwsArgumentError);
    });
  });
}
