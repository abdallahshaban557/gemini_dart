import '../models/content.dart';
import '../models/response.dart';

/// Represents a single message in a conversation
class ConversationMessage {
  /// The role of the message sender ('user' or 'model')
  final String role;

  /// The content parts of the message
  final List<Content> parts;

  /// Creates a new ConversationMessage
  const ConversationMessage({
    required this.role,
    required this.parts,
  });

  /// Create a user message from text
  factory ConversationMessage.user(String text) => ConversationMessage(
        role: 'user',
        parts: [TextContent(text)],
      );

  /// Create a user message from content list
  factory ConversationMessage.userWithContent(List<Content> content) =>
      ConversationMessage(
        role: 'user',
        parts: content,
      );

  /// Create a model message from response
  factory ConversationMessage.fromResponse(GeminiResponse response) {
    final parts = <Content>[];

    // Extract content from candidates
    for (final candidate in response.candidates) {
      parts.add(candidate.content);
    }

    return ConversationMessage(
      role: 'model',
      parts: parts,
    );
  }

  /// Convert to API format
  Map<String, dynamic> toJson() => {
        'role': role,
        'parts': parts.map((part) => _contentToPart(part)).toList(),
      };

  /// Convert Content object to API part format
  Map<String, dynamic> _contentToPart(Content content) {
    if (content is TextContent) {
      return {'text': content.text};
    } else if (content is ImageContent) {
      return {
        'inlineData': {
          'mimeType': content.mimeType,
          'data': content.data,
        }
      };
    } else if (content is VideoContent) {
      return {
        'fileData': {
          'mimeType': content.mimeType,
          'fileUri': content.fileUri,
        }
      };
    } else {
      throw ArgumentError('Unsupported content type: ${content.runtimeType}');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConversationMessage &&
        other.role == role &&
        _listEquals(other.parts, parts);
  }

  @override
  int get hashCode => Object.hash(role, parts);

  @override
  String toString() =>
      'ConversationMessage(role: $role, parts: ${parts.length})';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Manages conversation context for multi-turn conversations
class ConversationContext {
  final List<ConversationMessage> _history = [];
  final int? _maxHistoryLength;

  /// Creates a new ConversationContext
  ConversationContext({
    int? maxHistoryLength,
  }) : _maxHistoryLength = maxHistoryLength;

  /// Get the conversation history
  List<ConversationMessage> get history => List.unmodifiable(_history);

  /// Get the number of messages in the conversation
  int get length => _history.length;

  /// Check if the conversation is empty
  bool get isEmpty => _history.isEmpty;

  /// Check if the conversation has messages
  bool get isNotEmpty => _history.isNotEmpty;

  /// Add a user message to the conversation
  void addUserMessage(String text) {
    addMessage(ConversationMessage.user(text));
  }

  /// Add a user message with multiple content parts
  void addUserMessageWithContent(List<Content> content) {
    addMessage(ConversationMessage.userWithContent(content));
  }

  /// Add a model response to the conversation
  void addModelResponse(GeminiResponse response) {
    addMessage(ConversationMessage.fromResponse(response));
  }

  /// Add a message to the conversation
  void addMessage(ConversationMessage message) {
    _history.add(message);
    _enforceMaxLength();
  }

  /// Clear the conversation history
  void clear() {
    _history.clear();
  }

  /// Get the last user message
  ConversationMessage? get lastUserMessage {
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i].role == 'user') {
        return _history[i];
      }
    }
    return null;
  }

  /// Get the last model message
  ConversationMessage? get lastModelMessage {
    for (int i = _history.length - 1; i >= 0; i--) {
      if (_history[i].role == 'model') {
        return _history[i];
      }
    }
    return null;
  }

  /// Convert conversation to API format for context
  List<Map<String, dynamic>> toApiFormat() =>
      _history.map((message) => message.toJson()).toList();

  /// Create a copy of the conversation context
  ConversationContext copy() {
    final newContext = ConversationContext(
      maxHistoryLength: _maxHistoryLength,
    );
    newContext._history.addAll(_history);
    return newContext;
  }

  /// Enforce maximum history length by removing oldest messages
  void _enforceMaxLength() {
    if (_maxHistoryLength != null && _history.length > _maxHistoryLength!) {
      final excess = _history.length - _maxHistoryLength!;
      _history.removeRange(0, excess);
    }
  }

  @override
  String toString() => 'ConversationContext(messages: ${_history.length})';
}
