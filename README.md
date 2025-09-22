# Gemini Dart

A comprehensive Dart package for integrating Google's Gemini AI models with support for text, image, and video processing.

## Features

- 🤖 **Multi-modal AI Integration**: Support for text, image, and video inputs
- 📱 **Flutter Widgets**: Pre-built widgets for easy Flutter integration
- 🔄 **Streaming Responses**: Real-time text generation with streaming support
- 🛡️ **Type Safety**: Strongly typed models and responses
- 🔧 **Configurable**: Extensive configuration options for different use cases
- 📦 **Cross-platform**: Works on iOS, Android, Web, and Desktop
- 🚀 **Performance Optimized**: Efficient file handling and caching mechanisms

## Installation

Add this package to your `pubspec.yaml`:

```yaml
dependencies:
  gemini_dart: ^0.1.0
```

For Flutter-specific features, also add:

```yaml
dependencies:
  flutter:
    sdk: flutter
  gemini_dart: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Basic Text Generation

```dart
import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  // Initialize the client
  final client = GeminiClient();
  await client.initialize('YOUR_API_KEY');

  // Generate text
  final response = await client.generateContent('Hello, Gemini!');
  print(response.text);

  // Clean up
  client.dispose();
}
```

### Multi-modal Content

```dart
import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  final client = GeminiClient();
  await client.initialize('YOUR_API_KEY');

  // Combine text and image
  final contents = [
    TextContent('Describe this image:'),
    ImageContent(imageBytes, 'image/jpeg'),
  ];

  final response = await client.generateFromContent(contents);
  print(response.text);
}
```

### Flutter Integration

```dart
import 'package:flutter/material.dart';
import 'package:gemini_dart/flutter_gemini.dart';

class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gemini Chat')),
      body: GeminiChat(
        apiKey: 'YOUR_API_KEY',
        onResponse: (response) {
          print('Received: ${response.text}');
        },
      ),
    );
  }
}
```

## Configuration

### Basic Configuration

```dart
final config = GeminiConfig(
  timeout: Duration(seconds: 30),
  maxRetries: 3,
  enableLogging: true,
);

final client = GeminiClient();
await client.initialize('YOUR_API_KEY', config: config);
```

### Generation Parameters

```dart
final generationConfig = GenerationConfig(
  temperature: 0.7,
  maxOutputTokens: 1000,
  topP: 0.9,
  topK: 40,
);

final response = await client.generateContent(
  'Write a story about AI',
  config: generationConfig,
);
```

## Supported Content Types

### Text

- Simple text prompts
- Multi-turn conversations
- Streaming responses

### Images

- JPEG, PNG, WebP formats
- Automatic resizing for size limits
- Multi-image analysis

### Video

- MP4, MOV formats
- Large file upload with progress tracking
- Frame-by-frame analysis

## Error Handling

The package provides comprehensive error handling:

```dart
try {
  final response = await client.generateContent('Hello');
} on GeminiAuthException catch (e) {
  print('Authentication error: ${e.message}');
} on GeminiRateLimitException catch (e) {
  print('Rate limit exceeded. Retry after: ${e.retryAfter}');
} on GeminiException catch (e) {
  print('Gemini error: ${e.message}');
}
```

## Flutter Widgets

### GeminiChat

A complete chat interface with message history and typing indicators.

### MediaPicker

Easy media selection for images and videos.

### ResponseViewer

Formatted display of AI responses with syntax highlighting.

## Examples

Check out the `/example` directory for complete examples:

- Basic text generation
- Multi-modal content processing
- Flutter chat application
- Video analysis workflow

## API Reference

For detailed API documentation, visit [pub.dev documentation](https://pub.dev/documentation/gemini_dart/latest/).

## Requirements

- Dart SDK: >=3.0.0 <4.0.0
- Flutter: >=3.10.0 (for Flutter features)
- Google AI API key

## Getting an API Key

1. Visit [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key
3. Add the key to your environment or configuration

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://pub.dev/documentation/gemini_dart/latest/)
- 🐛 [Issue Tracker](https://github.com/your-username/gemini_dart/issues)
- 💬 [Discussions](https://github.com/your-username/gemini_dart/discussions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each version.
