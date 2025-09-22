# How to Run the Text Generation Example

This guide shows you how to run the `text_generation_example.dart` file that demonstrates the text generation functionality.

## Prerequisites

1. **Get a Gemini API Key**

   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Sign in with your Google account
   - Click "Create API Key"
   - Copy the generated API key

2. **Install Dependencies**
   ```bash
   dart pub get
   ```

## Running the Example

### Option 1: Using Environment Variable (Recommended)

Set your API key as an environment variable:

```bash
export GEMINI_API_KEY="your-actual-api-key-here"
dart run example/text_generation_example.dart
```

### Option 2: Edit the Example File

1. Open `example/text_generation_example.dart`
2. Find this line:
   ```dart
   final apiKey = Platform.environment['GEMINI_API_KEY'] ?? 'AIzaSyCHv9s5b52BPHqh4SlAJRQVF7O5C36hVl0';
   ```
3. Replace the placeholder with your actual API key:
   ```dart
   final apiKey = Platform.environment['GEMINI_API_KEY'] ?? 'your-actual-api-key-here';
   ```
4. Run the example:
   ```bash
   dart run example/text_generation_example.dart
   ```

## Expected Output

When you run the example successfully, you should see output like this:

```
=== Basic Text Generation ===
Response: A mind of wires, code, and gleam,
A thinking thing, a waking dream...
Tokens used: 99

=== Text Generation with Configuration ===
Response: Imagine a light switch. It can be either ON or OFF...

=== Conversation Context Example ===
AI: That's wonderful, Alice! It's great that you love programming...
AI: Your name is Alice and you love programming.

Conversation history length: 4

=== Streaming Text Generation ===
Streaming response:
Streaming not available or not supported: [error details]

=== Multi-Modal Content ===
Analysis: The text "The future of AI is bright..." contains themes of...
```

## What the Example Demonstrates

The example shows five key features:

1. **Basic Text Generation**: Simple prompt-to-text generation
2. **Configuration**: Using custom generation parameters (temperature, max tokens)
3. **Conversation Context**: Multi-turn conversations that remember previous messages
4. **Streaming**: Attempting to stream responses (may not be supported by all models)
5. **Multi-Modal Content**: Processing multiple text parts together

## Troubleshooting

### Common Errors

1. **"Authentication not configured"**

   - Make sure you've set a valid API key
   - Check that your API key is correct and active

2. **"Model not found"**

   - The example uses `gemini-1.5-flash` model
   - Make sure this model is available in your region

3. **"Rate limit exceeded"**

   - You've made too many requests too quickly
   - Wait a moment and try again

4. **"Invalid API key format"**
   - Check that your API key starts with "AIza"
   - Make sure there are no extra spaces or characters

### Debug Mode

To see raw API responses, run the debug example:

```bash
dart run example/debug_api_response.dart
```

This will show you the exact JSON response from the Gemini API.

## Next Steps

After running the example successfully, you can:

1. Modify the prompts to test different types of content generation
2. Experiment with different generation configurations
3. Try building your own application using the `TextHandler` class
4. Run the test suite to see more usage examples: `dart test test/unit/handlers/`

## API Reference

- `TextHandler` - Main class for text generation
- `ConversationContext` - Manages conversation history
- `GenerationConfig` - Configuration for generation parameters
- `GeminiResponse` - Response object containing generated text and metadata
