# Running Integration Tests

The integration tests require a valid Gemini API key to run against the actual Google Gemini API.

## Getting a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

## Running Integration Tests

### Method 1: Using the Helper Scripts (Recommended)

#### On macOS/Linux:

```bash
# Option 1: Create a .env file (recommended)
cp .env.example .env
# Edit .env and add your API key

# Then run:
./run_integration_tests.sh

# Option 2: Pass API key directly
./run_integration_tests.sh "your-api-key-here"
```

#### On Windows:

```cmd
# Option 1: Create a .env file (recommended)
copy .env.example .env
# Edit .env and add your API key

# Then run:
run_integration_tests.bat

# Option 2: Pass API key directly
run_integration_tests.bat "your-api-key-here"
```

### Method 2: Environment Variable

#### On macOS/Linux:

```bash
export GEMINI_API_KEY="your-api-key-here"
dart test test/integration/
```

#### On Windows (Command Prompt):

```cmd
set GEMINI_API_KEY=your-api-key-here
dart test test/integration/
```

#### On Windows (PowerShell):

```powershell
$env:GEMINI_API_KEY="your-api-key-here"
dart test test/integration/
```

### Method 3: One-liner

#### On macOS/Linux:

```bash
GEMINI_API_KEY="your-api-key-here" dart test test/integration/
```

### Method 4: Compile-time Environment Variable

```bash
dart test test/integration/ --dart-define=GEMINI_API_KEY=your-api-key-here
```

## Test Categories

The integration tests are organized into several categories:

- **Text Generation Tests** (`test/integration/text_generation_test.dart`)

  - Basic text generation
  - Generation with configuration
  - Streaming content generation
  - Conversation context handling

- **Gemini Client Tests** (`test/integration/gemini_client_test.dart`)

  - Client initialization
  - Multi-modal content generation
  - Image analysis
  - Error handling

- **Image Processing Tests** (`test/integration/image_processing_test.dart`)
  - Image content handling
  - Multi-modal prompts with images

## Running Specific Test Files

You can run specific integration test files:

```bash
# Run only text generation tests
GEMINI_API_KEY="your-key" dart test test/integration/text_generation_test.dart

# Run only client tests
GEMINI_API_KEY="your-key" dart test test/integration/gemini_client_test.dart

# Run only image processing tests
GEMINI_API_KEY="your-key" dart test test/integration/image_processing_test.dart
```

## Troubleshooting

### API Key Issues

- Make sure your API key is valid and active
- Check that you have sufficient quota/credits
- Ensure the API key has the necessary permissions

### Rate Limiting

- The tests include retry logic for rate limiting
- If you hit rate limits, wait a few minutes and try again
- Consider running tests with fewer concurrent requests

### Model Availability

- Some tests use specific Gemini models (e.g., `gemini-2.5-flash`)
- If you get "model not found" errors, check the available models for your API key
- You may need to update model names in the tests if Google changes model availability

## Security Note

⚠️ **Never commit your API key to version control!**

- The `.env` file is already added to `.gitignore`
- Always use environment variables or secure secret management
- Rotate your API keys regularly
- Monitor your API usage and billing
