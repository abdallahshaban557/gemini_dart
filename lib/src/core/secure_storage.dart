import 'dart:convert';
import 'platform_imports.dart';
import 'package:path/path.dart' as path;

/// Secure storage interface for storing sensitive data like API keys
abstract class SecureStorageInterface {
  Future<void> store(String key, String value);
  Future<String?> retrieve(String key);
  Future<void> delete(String key);
  Future<void> clear();
}

/// Basic secure storage implementation
/// Note: In production, consider using platform-specific secure storage solutions
class SecureStorage implements SecureStorageInterface {
  SecureStorage({String? customPath}) {
    if (customPath != null) {
      _storagePath = customPath;
    } else {
      // Use system temp directory for basic storage
      final tempDir = PlatformDirectory.systemTemp;
      _storagePath = path.join(tempDir.path, _storageFileName);
    }
  }
  static const String _storageFileName = '.gemini_secure_storage';
  late final String _storagePath;
  Map<String, String>? _cache;

  /// Loads the storage cache from file
  Future<Map<String, String>> _loadCache() async {
    if (_cache != null) {
      return _cache!;
    }

    final file = PlatformFile(_storagePath);
    if (!await file.exists()) {
      _cache = <String, String>{};
      return _cache!;
    }

    try {
      final content = await file.readAsString();
      if (content.isEmpty) {
        _cache = <String, String>{};
        return _cache!;
      }

      // Simple base64 encoding for basic obfuscation
      final decoded = utf8.decode(base64.decode(content));
      final Map<String, dynamic> data = json.decode(decoded);
      _cache = data.cast<String, String>();
      return _cache!;
    } catch (e) {
      // If file is corrupted, start fresh
      _cache = <String, String>{};
      return _cache!;
    }
  }

  /// Saves the cache to file
  Future<void> _saveCache() async {
    if (_cache == null) return;

    final file = PlatformFile(_storagePath);
    await file.parent.create(recursive: true);

    // Simple base64 encoding for basic obfuscation
    final jsonString = json.encode(_cache);
    final encoded = base64.encode(utf8.encode(jsonString));
    await file.writeAsString(encoded);
  }

  @override
  Future<void> store(String key, String value) async {
    final cache = await _loadCache();
    cache[key] = value;
    await _saveCache();
  }

  @override
  Future<String?> retrieve(String key) async {
    final cache = await _loadCache();
    return cache[key];
  }

  @override
  Future<void> delete(String key) async {
    final cache = await _loadCache();
    cache.remove(key);
    await _saveCache();
  }

  @override
  Future<void> clear() async {
    _cache = <String, String>{};
    await _saveCache();
  }
}

/// In-memory storage for testing purposes
class InMemorySecureStorage implements SecureStorageInterface {
  final Map<String, String> _storage = <String, String>{};

  @override
  Future<void> store(String key, String value) async {
    _storage[key] = value;
  }

  @override
  Future<String?> retrieve(String key) async => _storage[key];

  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }

  @override
  Future<void> clear() async {
    _storage.clear();
  }
}
