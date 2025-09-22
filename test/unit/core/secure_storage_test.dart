import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:gemini_dart/src/core/secure_storage.dart';

void main() {
  group('InMemorySecureStorage', () {
    late InMemorySecureStorage storage;

    setUp(() {
      storage = InMemorySecureStorage();
    });

    test('should store and retrieve values', () async {
      await storage.store('key1', 'value1');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, equals('value1'));
    });

    test('should return null for non-existent keys', () async {
      final retrieved = await storage.retrieve('non_existent');
      expect(retrieved, isNull);
    });

    test('should delete stored values', () async {
      await storage.store('key1', 'value1');
      await storage.delete('key1');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, isNull);
    });

    test('should clear all stored values', () async {
      await storage.store('key1', 'value1');
      await storage.store('key2', 'value2');
      await storage.clear();

      final retrieved1 = await storage.retrieve('key1');
      final retrieved2 = await storage.retrieve('key2');
      expect(retrieved1, isNull);
      expect(retrieved2, isNull);
    });

    test('should overwrite existing values', () async {
      await storage.store('key1', 'value1');
      await storage.store('key1', 'value2');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, equals('value2'));
    });
  });

  group('SecureStorage', () {
    late SecureStorage storage;
    late Directory tempDir;
    late String storagePath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('secure_storage_test');
      storagePath = path.join(tempDir.path, 'test_storage');
      storage = SecureStorage(customPath: storagePath);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('should store and retrieve values', () async {
      await storage.store('key1', 'value1');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, equals('value1'));
    });

    test('should persist values across instances', () async {
      await storage.store('key1', 'value1');

      // Create new instance with same path
      final newStorage = SecureStorage(customPath: storagePath);
      final retrieved = await newStorage.retrieve('key1');
      expect(retrieved, equals('value1'));
    });

    test('should return null for non-existent keys', () async {
      final retrieved = await storage.retrieve('non_existent');
      expect(retrieved, isNull);
    });

    test('should delete stored values', () async {
      await storage.store('key1', 'value1');
      await storage.delete('key1');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, isNull);
    });

    test('should clear all stored values', () async {
      await storage.store('key1', 'value1');
      await storage.store('key2', 'value2');
      await storage.clear();

      final retrieved1 = await storage.retrieve('key1');
      final retrieved2 = await storage.retrieve('key2');
      expect(retrieved1, isNull);
      expect(retrieved2, isNull);
    });

    test('should handle multiple key-value pairs', () async {
      await storage.store('key1', 'value1');
      await storage.store('key2', 'value2');
      await storage.store('key3', 'value3');

      final retrieved1 = await storage.retrieve('key1');
      final retrieved2 = await storage.retrieve('key2');
      final retrieved3 = await storage.retrieve('key3');

      expect(retrieved1, equals('value1'));
      expect(retrieved2, equals('value2'));
      expect(retrieved3, equals('value3'));
    });

    test('should overwrite existing values', () async {
      await storage.store('key1', 'value1');
      await storage.store('key1', 'value2');
      final retrieved = await storage.retrieve('key1');
      expect(retrieved, equals('value2'));
    });

    test('should handle empty storage file gracefully', () async {
      // Create empty file
      final file = File(storagePath);
      await file.parent.create(recursive: true);
      await file.writeAsString('');

      final retrieved = await storage.retrieve('key1');
      expect(retrieved, isNull);

      // Should still be able to store new values
      await storage.store('key1', 'value1');
      final newRetrieved = await storage.retrieve('key1');
      expect(newRetrieved, equals('value1'));
    });

    test('should handle corrupted storage file gracefully', () async {
      // Create corrupted file
      final file = File(storagePath);
      await file.parent.create(recursive: true);
      await file.writeAsString('corrupted data');

      final retrieved = await storage.retrieve('key1');
      expect(retrieved, isNull);

      // Should still be able to store new values
      await storage.store('key1', 'value1');
      final newRetrieved = await storage.retrieve('key1');
      expect(newRetrieved, equals('value1'));
    });
  });
}
