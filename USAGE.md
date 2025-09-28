# Usage Guide

This guide shows you how to use the Gemini Dart package to integrate Google's Gemini AI models into your Dart or Flutter applications.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  gemini_dart: ^0.1.0
```

Then run:

```bash
dart pub get
# or for Flutter
flutter pub get
```

## Getting Started

### 1. Get Your API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Copy the API key for use in your application

### 2. Set Up Environment Variable (Recommended)

Create a `.env` file or set an environment variable:

```bash
export GEMINI_API_KEY="your-actual-api-key-here"
```

### Option 2: Edit the Example File

1. Open `example/text_generation_example.dart`
2. Find this line:
   ```dart
   final apiKey = Platform.environment['GEMINI_API_KEY'] ?? 'your-actual-api-key-here';
   ```
3. Replace the placeholder with your actual API key:
   ```dart
   final apiKey = Platform.environment['GEMINI_API_KEY'] ?? 'your-actual-api-key-here';
   ```

## Basic Usage

### Text Generation

```dart
import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  // Initialize the client
  final client = GeminiClient(model: GeminiModels.gemini15Flash);
  await client.initialize(apiKey: 'your-api-key');

  // Generate text
  final response = await client.generateText(
    prompt: 'Write a short story about a robot learning to paint',
  );

  print(response.text);
}
```

### Image Generation

```dart
import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  // Use image generation model
  final client = GeminiClient(model: GeminiModels.gemini25FlashImagePreview);
  await client.initialize(apiKey: 'your-api-key');

  // Generate image
  final response = await client.generateImage(
    prompt: 'A futuristic city at sunset with flying cars',
  );

  // Save the generated image
  final file = File('generated_image.png');
  await file.writeAsBytes(response.images.first.data);
}
```

### Multimodal Content Analysis

```dart
import 'package:gemini_dart/gemini_dart.dart';

void main() async {
  // Use multimodal model
  final client = GeminiClient(model: GeminiModels.gemini15Pro);
  await client.initialize(apiKey: 'your-api-key');

  // Analyze an image
  final imageFile = await GeminiFile.fromFile(File('path/to/image.jpg'));

  final response = await client.createMultiModalPrompt(
    text: 'What do you see in this image? Describe it in detail.',
    files: [imageFile],
  );

  print(response.text);
}
```

## Advanced Features

### Model Capabilities

Each model has specific capabilities. You can check them:

```dart
final model = GeminiModels.gemini15Pro;
print('Can generate text: ${model.canGenerateText}');
print('Can generate images: ${model.canGenerateImages}');
print('Can analyze images: ${model.canAnalyzeImages}');
print('Supports multimodal: ${model.supportsMultiModalInput}');
```

### Generation Configuration

Customize the generation behavior:

```dart
final config = GenerationConfig(
  temperature: 0.8,
  maxOutputTokens: 1000,
  topP: 0.9,
  topK: 40,
);

final response = await client.generateText(
  prompt: 'Write a creative story',
  config: config,
);
```

### Conversation Context

Maintain conversation history:

```dart
final context = client.createConversationContext();

// First message
await client.generateText(
  prompt: 'Hello, I want to learn about quantum physics',
  context: context,
);

// Follow-up message (with context)
final response = await client.generateText(
  prompt: 'Can you explain it in simple terms?',
  context: context,
);
```

## Error Handling

```dart
try {
  final response = await client.generateText(prompt: 'Hello');
  print(response.text);
} on GeminiAuthException catch (e) {
  print('Authentication error: ${e.message}');
} on GeminiValidationException catch (e) {
  print('Validation error: ${e.message}');
} on GeminiNetworkException catch (e) {
  print('Network error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

## Available Models

- **gemini15Flash**: Fast text generation
- **gemini15Pro**: Advanced multimodal capabilities
- **gemini25Flash**: Latest text generation
- **gemini25FlashImagePreview**: Image generation (preview)

## More Examples

Check the `example/` directory for more comprehensive examples:

- `correct_usage_demo.dart` - Basic usage patterns
- `working_image_generation.dart` - Image generation examples
- `test_basic_functionality.dart` - Testing different features

## Support

For issues and questions:

- GitHub Issues: https://github.com/abdallahshaban557/gemini_dart/issues
- Documentation: https://pub.dev/packages/gemini_dart
