import 'package:test/test.dart';
import 'package:gemini_dart/src/models/response.dart';
import 'package:gemini_dart/src/models/content.dart';

void main() {
  group('SafetyRating', () {
    test('should create SafetyRating with valid data', () {
      const category = 'HARM_CATEGORY_HARASSMENT';
      const probability = 'NEGLIGIBLE';
      final rating = SafetyRating(category: category, probability: probability);

      expect(rating.category, equals(category));
      expect(rating.probability, equals(probability));
    });

    test('should serialize to JSON correctly', () {
      final rating = SafetyRating(
          category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE');
      final json = rating.toJson();

      expect(
          json,
          equals({
            'category': 'HARM_CATEGORY_HARASSMENT',
            'probability': 'NEGLIGIBLE',
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'category': 'HARM_CATEGORY_HARASSMENT',
        'probability': 'NEGLIGIBLE',
      };
      final rating = SafetyRating.fromJson(json);

      expect(rating.category, equals('HARM_CATEGORY_HARASSMENT'));
      expect(rating.probability, equals('NEGLIGIBLE'));
    });

    test(
        'should throw ArgumentError when deserializing without required fields',
        () {
      expect(() => SafetyRating.fromJson({}), throwsArgumentError);
      expect(
          () => SafetyRating.fromJson({'category': 'HARM_CATEGORY_HARASSMENT'}),
          throwsArgumentError);
      expect(() => SafetyRating.fromJson({'probability': 'NEGLIGIBLE'}),
          throwsArgumentError);
    });

    test('should implement equality correctly', () {
      final rating1 = SafetyRating(
          category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE');
      final rating2 = SafetyRating(
          category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE');
      final rating3 = SafetyRating(
          category: 'HARM_CATEGORY_HATE_SPEECH', probability: 'NEGLIGIBLE');

      expect(rating1, equals(rating2));
      expect(rating1, isNot(equals(rating3)));
    });

    test('should implement toString correctly', () {
      final rating = SafetyRating(
          category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE');
      expect(
          rating.toString(),
          equals(
              'SafetyRating(category: HARM_CATEGORY_HARASSMENT, probability: NEGLIGIBLE)'));
    });
  });

  group('PromptFeedback', () {
    test('should create PromptFeedback with valid data', () {
      final safetyRatings = [
        SafetyRating(
            category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE'),
      ];
      final feedback = PromptFeedback(safetyRatings: safetyRatings);

      expect(feedback.safetyRatings, equals(safetyRatings));
      expect(feedback.blockReason, isNull);
    });

    test('should create PromptFeedback with block reason', () {
      const blockReason = 'SAFETY';
      final feedback =
          PromptFeedback(blockReason: blockReason, safetyRatings: []);

      expect(feedback.blockReason, equals(blockReason));
    });

    test('should serialize to JSON correctly', () {
      final safetyRatings = [
        SafetyRating(
            category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE'),
      ];
      final feedback =
          PromptFeedback(blockReason: 'SAFETY', safetyRatings: safetyRatings);
      final json = feedback.toJson();

      expect(
          json,
          equals({
            'blockReason': 'SAFETY',
            'safetyRatings': [
              {
                'category': 'HARM_CATEGORY_HARASSMENT',
                'probability': 'NEGLIGIBLE'
              },
            ],
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'blockReason': 'SAFETY',
        'safetyRatings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'probability': 'NEGLIGIBLE'},
        ],
      };
      final feedback = PromptFeedback.fromJson(json);

      expect(feedback.blockReason, equals('SAFETY'));
      expect(feedback.safetyRatings.length, equals(1));
      expect(feedback.safetyRatings.first.category,
          equals('HARM_CATEGORY_HARASSMENT'));
    });

    test('should handle empty safety ratings', () {
      final json = {'safetyRatings': <dynamic>[]};
      final feedback = PromptFeedback.fromJson(json);

      expect(feedback.safetyRatings, isEmpty);
      expect(feedback.blockReason, isNull);
    });
  });

  group('UsageMetadata', () {
    test('should create UsageMetadata with valid data', () {
      const promptTokens = 10;
      const candidateTokens = 20;
      const totalTokens = 30;

      final metadata = UsageMetadata(
        promptTokenCount: promptTokens,
        candidatesTokenCount: candidateTokens,
        totalTokenCount: totalTokens,
      );

      expect(metadata.promptTokenCount, equals(promptTokens));
      expect(metadata.candidatesTokenCount, equals(candidateTokens));
      expect(metadata.totalTokenCount, equals(totalTokens));
    });

    test('should serialize to JSON correctly', () {
      final metadata = UsageMetadata(
        promptTokenCount: 10,
        candidatesTokenCount: 20,
        totalTokenCount: 30,
      );
      final json = metadata.toJson();

      expect(
          json,
          equals({
            'promptTokenCount': 10,
            'candidatesTokenCount': 20,
            'totalTokenCount': 30,
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'promptTokenCount': 10,
        'candidatesTokenCount': 20,
        'totalTokenCount': 30,
      };
      final metadata = UsageMetadata.fromJson(json);

      expect(metadata.promptTokenCount, equals(10));
      expect(metadata.candidatesTokenCount, equals(20));
      expect(metadata.totalTokenCount, equals(30));
    });

    test('should handle null values', () {
      final metadata = UsageMetadata();
      final json = metadata.toJson();

      expect(json, isEmpty);
    });
  });

  group('Candidate', () {
    test('should create Candidate with valid data', () {
      final content = TextContent('Hello, world!');
      final safetyRatings = [
        SafetyRating(
            category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE'),
      ];

      final candidate = Candidate(
        content: content,
        finishReason: 'STOP',
        index: 0,
        safetyRatings: safetyRatings,
      );

      expect(candidate.content, equals(content));
      expect(candidate.finishReason, equals('STOP'));
      expect(candidate.index, equals(0));
      expect(candidate.safetyRatings, equals(safetyRatings));
    });

    test('should serialize to JSON correctly', () {
      final content = TextContent('Hello, world!');
      final safetyRatings = [
        SafetyRating(
            category: 'HARM_CATEGORY_HARASSMENT', probability: 'NEGLIGIBLE'),
      ];

      final candidate = Candidate(
        content: content,
        finishReason: 'STOP',
        index: 0,
        safetyRatings: safetyRatings,
      );

      final json = candidate.toJson();

      expect(json['content'], equals(content.toJson()));
      expect(json['finishReason'], equals('STOP'));
      expect(json['index'], equals(0));
      expect(json['safetyRatings'], isA<List>());
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'content': {'type': 'text', 'text': 'Hello, world!'},
        'finishReason': 'STOP',
        'index': 0,
        'safetyRatings': [
          {'category': 'HARM_CATEGORY_HARASSMENT', 'probability': 'NEGLIGIBLE'},
        ],
      };

      final candidate = Candidate.fromJson(json);

      expect(candidate.content, isA<TextContent>());
      expect((candidate.content as TextContent).text, equals('Hello, world!'));
      expect(candidate.finishReason, equals('STOP'));
      expect(candidate.index, equals(0));
      expect(candidate.safetyRatings.length, equals(1));
    });

    test('should throw ArgumentError when deserializing without content', () {
      final json = {
        'finishReason': 'STOP',
        'index': 0,
        'safetyRatings': [],
      };

      expect(() => Candidate.fromJson(json), throwsArgumentError);
    });

    test('should handle default index when not provided', () {
      final json = {
        'content': {'type': 'text', 'text': 'Hello'},
        'safetyRatings': [],
      };

      final candidate = Candidate.fromJson(json);
      expect(candidate.index, equals(0));
    });
  });

  group('GeminiResponse', () {
    test('should create GeminiResponse with valid data', () {
      final candidates = [
        Candidate(
          content: TextContent('Hello, world!'),
          index: 0,
          safetyRatings: [],
        ),
      ];

      final response = GeminiResponse(
        text: 'Hello, world!',
        candidates: candidates,
      );

      expect(response.text, equals('Hello, world!'));
      expect(response.candidates, equals(candidates));
      expect(response.promptFeedback, isNull);
      expect(response.usageMetadata, isNull);
    });

    test('should serialize to JSON correctly', () {
      final candidates = [
        Candidate(
          content: TextContent('Hello, world!'),
          index: 0,
          safetyRatings: [],
        ),
      ];

      final response = GeminiResponse(
        text: 'Hello, world!',
        candidates: candidates,
      );

      final json = response.toJson();

      expect(json['text'], equals('Hello, world!'));
      expect(json['candidates'], isA<List>());
      expect(json.containsKey('promptFeedback'), isFalse);
      expect(json.containsKey('usageMetadata'), isFalse);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'candidates': [
          {
            'content': {'type': 'text', 'text': 'Hello, world!'},
            'index': 0,
            'safetyRatings': [],
          },
        ],
      };

      final response = GeminiResponse.fromJson(json);

      expect(response.candidates.length, equals(1));
      expect(response.text,
          equals('Hello, world!')); // Extracted from first candidate
      expect(response.promptFeedback, isNull);
      expect(response.usageMetadata, isNull);
    });

    test('should extract text from first candidate', () {
      final json = {
        'candidates': [
          {
            'content': {'type': 'text', 'text': 'First response'},
            'index': 0,
            'safetyRatings': [],
          },
          {
            'content': {'type': 'text', 'text': 'Second response'},
            'index': 1,
            'safetyRatings': [],
          },
        ],
      };

      final response = GeminiResponse.fromJson(json);

      expect(response.text, equals('First response'));
    });

    test('should handle empty candidates list', () {
      final json = {'candidates': <dynamic>[]};
      final response = GeminiResponse.fromJson(json);

      expect(response.candidates, isEmpty);
      expect(response.text, isNull);
    });

    test('should include all optional fields when present', () {
      final json = {
        'candidates': [
          {
            'content': {'type': 'text', 'text': 'Hello'},
            'index': 0,
            'safetyRatings': [],
          },
        ],
        'promptFeedback': {
          'safetyRatings': [],
        },
        'usageMetadata': {
          'totalTokenCount': 10,
        },
      };

      final response = GeminiResponse.fromJson(json);

      expect(response.promptFeedback, isNotNull);
      expect(response.usageMetadata, isNotNull);
      expect(response.usageMetadata!.totalTokenCount, equals(10));
    });
  });
}
