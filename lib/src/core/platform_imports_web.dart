// Platform-specific imports for web platform
import 'dart:html' as html show File, FileReader;
import 'dart:async';

// Web-specific implementations
class PlatformFile {
  final html.File _file;

  PlatformFile(this._file);

  String get path => _file.name;

  Future<List<int>> readAsBytes() async {
    final reader = html.FileReader();
    final completer = Completer<List<int>>();

    reader.onLoad.listen((event) {
      final result = reader.result as List<int>;
      completer.complete(result);
    });

    reader.onError.listen((event) {
      completer.completeError(Exception('Failed to read file'));
    });

    reader.readAsArrayBuffer(_file);
    return completer.future;
  }

  Future<void> writeAsBytes(List<int> bytes) async {
    throw UnsupportedError('File writing not supported on web platform');
  }

  Future<bool> exists() async {
    return true; // Assume file exists if we have a File object
  }

  String get fileName => _file.name;
}

class PlatformDirectory {
  final String path;

  PlatformDirectory(this.path);

  Future<PlatformDirectory> create({bool recursive = false}) async {
    throw UnsupportedError('Directory creation not supported on web platform');
  }
}

class PlatformSocketException implements Exception {
  final String message;
  PlatformSocketException(this.message);
}

class PlatformHttpException implements Exception {
  final String message;
  PlatformHttpException(this.message);
}

class PlatformPlatform {
  static bool get isWeb => true;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isWindows => false;
}
