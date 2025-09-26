import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gemini_dart/gemini_dart.dart';

/// Flutter example demonstrating Gemini API integration
void main() {
  runApp(const GeminiApp());
}

class GeminiApp extends StatelessWidget {
  const GeminiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini API Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const GeminiHomePage(),
    );
  }
}

class GeminiHomePage extends StatefulWidget {
  const GeminiHomePage({super.key});

  @override
  State<GeminiHomePage> createState() => _GeminiHomePageState();
}

class _GeminiHomePageState extends State<GeminiHomePage> {
  final TextEditingController _promptController = TextEditingController();
  final List<String> _messages = [];
  bool _isLoading = false;
  GeminiClient? _client;

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _messages.add('❌ Please set GEMINI_API_KEY environment variable');
      });
      return;
    }

    try {
      _client = GeminiClient();
      await _client!.initialize(apiKey);
      setState(() {
        _messages.add('✅ Gemini client initialized successfully');
      });
    } catch (e) {
      setState(() {
        _messages.add('❌ Failed to initialize client: $e');
      });
    }
  }

  Future<void> _generateText() async {
    if (_client == null || _promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add('👤 User: ${_promptController.text}');
    });

    try {
      final result = await _client!.generateText(
        prompt: _promptController.text,
        config: const GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 200,
        ),
      );

      setState(() {
        _messages.add('🤖 Assistant: ${result.text}');
        _promptController.clear();
      });
    } catch (e) {
      setState(() {
        _messages.add('❌ Error: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateImage() async {
    if (_client == null || _promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add('🎨 Generating image: ${_promptController.text}');
    });

    try {
      final result = await _client!.generateImage(
        _promptController.text,
        config: const GenerationConfig(
          temperature: 0.8,
        ),
      );

      setState(() {
        _messages.add('✅ Image generated: ${result.text}');
        _promptController.clear();
      });
    } catch (e) {
      setState(() {
        _messages.add('❌ Image generation failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _streamText() async {
    if (_client == null || _promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _messages.add('🌊 Streaming: ${_promptController.text}');
      _messages.add('🤖 Assistant: ');
    });

    try {
      String streamedText = '';
      await for (final chunk in _client!.generateTextStream(
        prompt: _promptController.text,
        config: const GenerationConfig(
          temperature: 0.8,
        ),
      )) {
        if (chunk.text?.isNotEmpty == true) {
          setState(() {
            streamedText += chunk.text!;
            _messages[_messages.length - 1] = '🤖 Assistant: $streamedText';
          });
        }
      }
    } catch (e) {
      setState(() {
        _messages.add('❌ Streaming failed: $e');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _client?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini API Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Input section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: 'Enter your prompt',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateText,
                      child: const Text('Generate Text'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _generateImage,
                      child: const Text('Generate Image'),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _streamText,
                      child: const Text('Stream Text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Messages section
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        color: message.startsWith('❌')
                            ? Colors.red
                            : message.startsWith('✅')
                                ? Colors.green
                                : Colors.black,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
