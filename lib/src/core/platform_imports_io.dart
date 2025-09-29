// Platform-specific imports for non-web platforms
import 'dart:io' as io
    show File, Directory, Platform, SocketException, HttpException;

// Re-export types for non-web platforms
typedef PlatformFile = io.File;
typedef PlatformDirectory = io.Directory;
typedef PlatformSocketException = io.SocketException;
typedef PlatformHttpException = io.HttpException;
typedef PlatformPlatform = io.Platform;
