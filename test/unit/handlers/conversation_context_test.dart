import 'package:test/test.dart';

import 'package:gemini_dart/src/handlers/conversation_context.dart';
import 'package:gemini_dart/src/models/content.dart';
import 'package:gemini_dart/src/models/response.dart';

void main() {
  group('ConversationMessage', () {
    test('should create user message from text', () {
      // Act
      final message = ConversationMessage.user('Hello');

      // Assert
      expect(message.role, equals('user'));
      expect(message.parts, hasLength(1));
      expect(message.parts.first, isA<TextContent>());
      expect((message.parts.first as TextContent).text, equals('Hello'));
    });

    test('should create user message from content list', () {
      // Arrange
      final contents = [
        TextContent('Hello'),
        TextContent('World'),
      ];

      // Act
      final message = ConversationMessage.userWithContent(contents);

      // Assert
      expect(message.role, equals('user'));
      expect(message.parts, hasLength(2));
      expect(message.parts, equals(contents));
    });

    test('should create model message from response', () {
      // Arrange
      final response = GeminiResponse(
        text: 'Hello there!',
        candidates: [
          Candidate(
            content: TextContent('Hello there!'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      );

      // Act
      final message = ConversationMessage.fromResponse(response);

      // Assert
      expect(message.role, equals('model'));
      expect(message.parts, hasLength(1));
      expect(message.parts.first, isA<TextContent>());
    });

    test('should convert to JSON format', () {
      // Arrange
      final message = ConversationMessage.user('Test message');

      // Act
      final json = message.toJson();

      // Assert
      expect(json['role'], equals('user'));
      expect(json['parts'], isA<List>());
      expect(json['parts'][0]['text'], equals('Test message'));
    });

    test('should handle equality correctly', () {
      // Arrange
      final message1 = ConversationMessage.user('Hello');
      final message2 = ConversationMessage.user('Hello');
      final message3 = ConversationMessage.user('World');

      // Assert
      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('should have correct string representation', () {
      // Arrange
      final message = ConversationMessage.user('Test');

      // Act
      final str = message.toString();

      // Assert
      expect(str, contains('ConversationMessage'));
      expect(str, contains('user'));
      expect(str, contains('1'));
    });
  });

  group('ConversationContext', () {
    late ConversationContext context;

    setUp(() {
      context = ConversationContext();
    });

    test('should start empty', () {
      // Assert
      expect(context.isEmpty, isTrue);
      expect(context.isNotEmpty, isFalse);
      expect(context.length, equals(0));
      expect(context.history, isEmpty);
    });

    test('should add user message', () {
      // Act
      context.addUserMessage('Hello');

      // Assert
      expect(context.length, equals(1));
      expect(context.isNotEmpty, isTrue);
      expect(context.history.first.role, equals('user'));
      expect(context.history.first.parts.first, isA<TextContent>());
    });

    test('should add user message with content', () {
      // Arrange
      final contents = [TextContent('Hello'), TextContent('World')];

      // Act
      context.addUserMessageWithContent(contents);

      // Assert
      expect(context.length, equals(1));
      expect(context.history.first.parts, hasLength(2));
      expect(context.history.first.parts, equals(contents));
    });

    test('should add model response', () {
      // Arrange
      final response = GeminiResponse(
        text: 'Hello!',
        candidates: [
          Candidate(
            content: TextContent('Hello!'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      );

      // Act
      context.addModelResponse(response);

      // Assert
      expect(context.length, equals(1));
      expect(context.history.first.role, equals('model'));
    });

    test('should add message directly', () {
      // Arrange
      final message = ConversationMessage.user('Direct message');

      // Act
      context.addMessage(message);

      // Assert
      expect(context.length, equals(1));
      expect(context.history.first, equals(message));
    });

    test('should clear conversation', () {
      // Arrange
      context.addUserMessage('Hello');
      context.addUserMessage('World');

      // Act
      context.clear();

      // Assert
      expect(context.isEmpty, isTrue);
      expect(context.length, equals(0));
    });

    test('should get last user message', () {
      // Arrange
      context.addUserMessage('First user message');
      context.addModelResponse(GeminiResponse(
        candidates: [
          Candidate(
            content: TextContent('Model response'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      ));
      context.addUserMessage('Second user message');

      // Act
      final lastUser = context.lastUserMessage;

      // Assert
      expect(lastUser, isNotNull);
      expect(lastUser!.role, equals('user'));
      expect((lastUser.parts.first as TextContent).text,
          equals('Second user message'));
    });

    test('should get last model message', () {
      // Arrange
      context.addUserMessage('User message');
      context.addModelResponse(GeminiResponse(
        candidates: [
          Candidate(
            content: TextContent('First model response'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      ));
      context.addModelResponse(GeminiResponse(
        candidates: [
          Candidate(
            content: TextContent('Second model response'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      ));

      // Act
      final lastModel = context.lastModelMessage;

      // Assert
      expect(lastModel, isNotNull);
      expect(lastModel!.role, equals('model'));
      expect((lastModel.parts.first as TextContent).text,
          equals('Second model response'));
    });

    test('should return null for last messages when empty', () {
      // Assert
      expect(context.lastUserMessage, isNull);
      expect(context.lastModelMessage, isNull);
    });

    test('should convert to API format', () {
      // Arrange
      context.addUserMessage('Hello');
      context.addModelResponse(GeminiResponse(
        candidates: [
          Candidate(
            content: TextContent('Hi there!'),
            index: 0,
            safetyRatings: [],
          ),
        ],
      ));

      // Act
      final apiFormat = context.toApiFormat();

      // Assert
      expect(apiFormat, hasLength(2));
      expect(apiFormat[0]['role'], equals('user'));
      expect(apiFormat[1]['role'], equals('model'));
    });

    test('should create copy of context', () {
      // Arrange
      context.addUserMessage('Original message');

      // Act
      final copy = context.copy();

      // Assert
      expect(copy.length, equals(context.length));
      expect(copy.history, equals(context.history));

      // Verify they are independent
      copy.addUserMessage('Copy message');
      expect(copy.length, equals(2));
      expect(context.length, equals(1));
    });

    test('should enforce maximum history length', () {
      // Arrange
      final limitedContext = ConversationContext(maxHistoryLength: 3);

      // Act
      limitedContext.addUserMessage('Message 1');
      limitedContext.addUserMessage('Message 2');
      limitedContext.addUserMessage('Message 3');
      limitedContext.addUserMessage('Message 4');
      limitedContext.addUserMessage('Message 5');

      // Assert
      expect(limitedContext.length, equals(3));
      expect((limitedContext.history.first.parts.first as TextContent).text,
          equals('Message 3'));
      expect((limitedContext.history.last.parts.first as TextContent).text,
          equals('Message 5'));
    });

    test('should have correct string representation', () {
      // Arrange
      context.addUserMessage('Test');

      // Act
      final str = context.toString();

      // Assert
      expect(str, contains('ConversationContext'));
      expect(str, contains('1'));
    });
  });
}
