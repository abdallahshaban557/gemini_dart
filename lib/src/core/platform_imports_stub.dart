// Stub file for platform imports
// This will be replaced by platform-specific implementations

// For non-web platforms
import 'dart:io' as io
    show File, Directory, Platform, SocketException, HttpException;

// Re-export types
typedef PlatformFile = io.File;
typedef PlatformDirectory = io.Directory;
typedef PlatformSocketException = io.SocketException;
typedef PlatformHttpException = io.HttpException;
typedef PlatformPlatform = io.Platform;
