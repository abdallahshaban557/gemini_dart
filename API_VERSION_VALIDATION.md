# API Version Validation

## Overview

The `GeminiConfig` class now uses an enum-based approach for API version validation, providing better type safety and IDE auto-complete support.

## Usage

### Basic Usage

```dart
import 'package:gemini_dart/src/models/gemini_config.dart';

// Using the default API version (v1)
const config = GeminiConfig();

// Explicitly setting API version to v1
const v1Config = GeminiConfig(
  apiVersion: ApiVersion.v1,
);

// Using the beta API version
const betaConfig = GeminiConfig(
  apiVersion: ApiVersion.v1beta,
);
```

### Available API Versions

The `ApiVersion` enum provides the following options:

- `ApiVersion.v1` - Version 1 (stable)
- `ApiVersion.v1beta` - Version 1 beta (preview features)

### IDE Auto-Complete

When typing `ApiVersion.` in your IDE, you'll get auto-complete suggestions showing only the valid API versions:

- `v1`
- `v1beta`

This prevents typos and ensures you're always using a supported API version.

### JSON Serialization

The enum values are automatically converted to their string representations when serializing to JSON:

```dart
const config = GeminiConfig(apiVersion: ApiVersion.v1beta);
final json = config.toJson();
print(json['apiVersion']); // Outputs: "v1beta"
```

### JSON Deserialization

When deserializing from JSON, string values are automatically converted back to the appropriate enum values:

```dart
final json = {'apiVersion': 'v1beta'};
final config = GeminiConfig.fromJson(json);
print(config.apiVersion); // Outputs: ApiVersion.v1beta
```

### Validation

API version validation is now handled automatically by the enum type system. Invalid values cannot be assigned at compile time, eliminating runtime validation errors for API versions.

### Migration from String-based API Versions

If you were previously using string values for API versions, update your code as follows:

**Before:**

```dart
const config = GeminiConfig(apiVersion: 'v1');
```

**After:**

```dart
const config = GeminiConfig(apiVersion: ApiVersion.v1);
```

**Before:**

```dart
const config = GeminiConfig(apiVersion: 'v1beta');
```

**After:**

```dart
const config = GeminiConfig(apiVersion: ApiVersion.v1beta);
```

## Benefits

1. **Type Safety**: Compile-time validation prevents invalid API versions
2. **Auto-Complete**: IDE support for discovering available API versions
3. **Refactoring Safety**: Renaming enum values updates all references automatically
4. **Documentation**: Enum values can include documentation for each API version
5. **Extensibility**: Easy to add new API versions in the future
