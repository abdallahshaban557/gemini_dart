import 'dart:io';

import 'package:gemini_dart/gemini_dart.dart';

/// Debug script for testing gemini-2.5-flash model and configuration options
void main() async {
  // Initialize authentication
  final auth = AuthenticationHandler();

  // Get API key from environment variable
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    print('Error: GEMINI_API_KEY environment variable is not set.');
    print('Please set it using: export GEMINI_API_KEY="your-api-key-here"');
    exit(1);
  }

  auth.setApiKey(apiKey);

  // Create configuration
  const config = GeminiConfig();

  // Create HTTP service
  final httpService = HttpService(auth: auth, config: config);

  try {
    print('=== Testing Model Availability ===');
    
    // Test 1: Check if gemini-2.5-flash model exists
    print('Testing gemini-2.5-flash model...');
    try {
      final response = await httpService.post(
        'models/gemini-2.5-flash:generateContent',
        body: {
          'contents': [
            {
              'parts': [
                {'text': 'Hello, are you gemini-2.5-flash?'}
              ]
            }
          ]
        },
      );
      print('✅ gemini-2.5-flash model is available');
      print('Response: ${response['candidates']?[0]?['content']?['parts']?[0]?['text']}');
    } catch (e) {
      print('❌ gemini-2.5-flash model error: $e');
      
      // Fallback: Test gemini-1.5-flash
      print('\nTesting fallback model gemini-1.5-flash...');
      try {
        final fallbackResponse = await httpService.post(
          'models/gemini-1.5-flash:generateContent',
          body: {
            'contents': [
              {
                'parts': [
                  {'text': 'Hello, are you gemini-1.5-flash?'}
                ]
              }
            ]
          ],
        );
        print('✅ gemini-1.5-flash model is available as fallback');
        print('Response: ${fallbackResponse['candidates']?[0]?['content']?['parts']?[0]?['text']}');
      } catch (fallbackError) {
        print('❌ gemini-1.5-flash model also failed: $fallbackError');
      }
    }

    print('\n=== Testing Configuration Options ===');
    
    // Test 2: Basic configuration options
    final testConfigs = [
      {
        'name': 'Low Temperature',
        'config': {'temperature': 0.1, 'maxOutputTokens': 50}
      },
      {
        'name': 'High Temperature',
        'config': {'temperature': 0.9, 'maxOutputTokens': 50}
      },
      {
        'name': 'Top-P Sampling',
        'config': {'topP': 0.8, 'maxOutputTokens': 50}
      },
      {
        'name': 'Top-K Sampling',
        'config': {'topK': 40, 'maxOutputTokens': 50}
      },
      {
        'name': 'Combined Settings',
        'config': {
          'temperature': 0.7,
          'topP': 0.9,
          'topK': 40,
          'maxOutputTokens': 100
        }
      },
    ];

    for (final testConfig in testConfigs) {
      print('\nTesting ${testConfig['name']}...');
      try {
        final response = await httpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: {
            'contents': [
              {
                'parts': [
                  {'text': 'Write a very short creative sentence about space.'}
                ]
              }
            ],
            'generationConfig': testConfig['config']
          },
        );
        
        final responseText = response['candidates']?[0]?['content']?['parts']?[0]?['text'];
        final tokenCount = response['usageMetadata']?['totalTokenCount'];
        
        print('✅ ${testConfig['name']} - Success');
        print('   Response: $responseText');
        print('   Tokens: $tokenCount');
        
      } catch (e) {
        print('❌ ${testConfig['name']} - Failed: $e');
      }
    }

    print('\n=== Testing Advanced Configuration Options ===');
    
    // Test 3: Advanced configuration options
    final advancedConfigs = [
      {
        'name': 'Stop Sequences',
        'config': {
          'maxOutputTokens': 100,
          'stopSequences': ['.', '!']
        }
      },
      {
        'name': 'Response MIME Type (JSON)',
        'config': {
          'maxOutputTokens': 100,
          'responseMimeType': 'application/json'
        }
      },
    ];

    for (final testConfig in advancedConfigs) {
      print('\nTesting ${testConfig['name']}...');
      try {
        final response = await httpService.post(
          'models/gemini-2.5-flash:generateContent',
          body: {
            'contents': [
              {
                'parts': [
                  {'text': 'Generate a simple response about AI'}
                ]
              }
            ],
            'generationConfig': testConfig['config']
          },
        );
        
        final responseText = response['candidates']?[0]?['content']?['parts']?[0]?['text'];
        print('✅ ${testConfig['name']} - Success');
        print('   Response: $responseText');
        
      } catch (e) {
        print('❌ ${testConfig['name']} - Failed: $e');
      }
    }

    print('\n=== Testing TextHandler with gemini-2.5-flash ===');
    
    // Test 4: Using TextHandler with the new model
    final textHandler = TextHandler(httpService: httpService, model: 'gemini-2.5-flash');
    
    try {
      // Test basic generation
      final response1 = await textHandler.generateContent('Say hello in a creative way');
      print('✅ TextHandler basic generation - Success');
      print('   Response: ${response1.text}');
      
      // Test with configuration
      const generationConfig = GenerationConfig(
        temperature: 0.8,
        maxOutputTokens: 75,
        topP: 0.9,
      );
      
      final response2 = await textHandler.generateContent(
        'Write a haiku about technology',
        config: generationConfig,
      );
      print('✅ TextHandler with config - Success');
      print('   Response: ${response2.text}');
      print('   Tokens: ${response2.usageMetadata?.totalTokenCount}');
      
    } catch (e) {
      print('❌ TextHandler test failed: $e');
    }

    print('\n=== Testing Model Comparison ===');
    
    // Test 5: Compare responses between models (if both available)
    final models = ['gemini-2.5-flash', 'gemini-1.5-flash'];
    const testPrompt = 'Explain AI in exactly 20 words.';
    
    for (final model in models) {
      print('\nTesting $model...');
      try {
        final response = await httpService.post(
          'models/$model:generateContent',
          body: {
            'contents': [
              {
                'parts': [
                  {'text': testPrompt}
                ]
              }
            ],
            'generationConfig': {
              'maxOutputTokens': 30,
              'temperature': 0.5
            }
          },
        );
        
        final responseText = response['candidates']?[0]?['content']?['parts']?[0]?['text'];
        final tokenCount = response['usageMetadata']?['totalTokenCount'];
        
        print('✅ $model - Success');
        print('   Response: $responseText');
        print('   Tokens: $tokenCount');
        
      } catch (e) {
        print('❌ $model - Failed: $e');
      }
    }

  } catch (e) {
    print('❌ Overall test failed: $e');
  } finally {
    httpService.dispose();
  }
}