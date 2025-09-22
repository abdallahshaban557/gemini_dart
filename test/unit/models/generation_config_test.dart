import 'package:test/test.dart';
import 'package:gemini_dart/src/models/generation_config.dart';

void main() {
  group('GenerationConfig', () {
    test('should create GenerationConfig with default values', () {
      const config = GenerationConfig();

      expect(config.temperature, isNull);
      expect(config.maxOutputTokens, isNull);
      expect(config.topP, isNull);
      expect(config.topK, isNull);
      expect(config.stopSequences, isNull);
      expect(config.responseMimeType, isNull);
    });

    test('should create GenerationConfig with all parameters', () {
      const temperature = 0.7;
      const maxOutputTokens = 1000;
      const topP = 0.9;
      const topK = 40;
      const stopSequences = ['STOP', 'END'];
      const responseMimeType = 'application/json';

      const config = GenerationConfig(
        temperature: temperature,
        maxOutputTokens: maxOutputTokens,
        topP: topP,
        topK: topK,
        stopSequences: stopSequences,
        responseMimeType: responseMimeType,
      );

      expect(config.temperature, equals(temperature));
      expect(config.maxOutputTokens, equals(maxOutputTokens));
      expect(config.topP, equals(topP));
      expect(config.topK, equals(topK));
      expect(config.stopSequences, equals(stopSequences));
      expect(config.responseMimeType, equals(responseMimeType));
    });

    test('should serialize to JSON correctly', () {
      const config = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
        topP: 0.9,
        topK: 40,
        stopSequences: ['STOP', 'END'],
        responseMimeType: 'application/json',
      );

      final json = config.toJson();

      expect(
          json,
          equals({
            'temperature': 0.7,
            'maxOutputTokens': 1000,
            'topP': 0.9,
            'topK': 40,
            'stopSequences': ['STOP', 'END'],
            'responseMimeType': 'application/json',
          }));
    });

    test('should serialize to JSON with only non-null values', () {
      const config = GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 500,
      );

      final json = config.toJson();

      expect(
          json,
          equals({
            'temperature': 0.5,
            'maxOutputTokens': 500,
          }));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'temperature': 0.7,
        'maxOutputTokens': 1000,
        'topP': 0.9,
        'topK': 40,
        'stopSequences': ['STOP', 'END'],
        'responseMimeType': 'application/json',
      };

      final config = GenerationConfig.fromJson(json);

      expect(config.temperature, equals(0.7));
      expect(config.maxOutputTokens, equals(1000));
      expect(config.topP, equals(0.9));
      expect(config.topK, equals(40));
      expect(config.stopSequences, equals(['STOP', 'END']));
      expect(config.responseMimeType, equals('application/json'));
    });

    test('should handle integer temperature in JSON', () {
      final json = {'temperature': 1};
      final config = GenerationConfig.fromJson(json);

      expect(config.temperature, equals(1.0));
    });

    test('should handle integer topP in JSON', () {
      final json = {'topP': 1};
      final config = GenerationConfig.fromJson(json);

      expect(config.topP, equals(1.0));
    });

    test('should create copy with modified values', () {
      const original = GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 500,
      );

      final modified = original.copyWith(
        temperature: 0.7,
        topK: 40,
      );

      expect(modified.temperature, equals(0.7));
      expect(modified.maxOutputTokens, equals(500)); // Unchanged
      expect(modified.topK, equals(40));
      expect(modified.topP, isNull); // Still null
    });

    test('should validate temperature range', () {
      const validConfig = GenerationConfig(temperature: 0.5);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidLow = GenerationConfig(temperature: -0.1);
      expect(() => invalidLow.validate(), throwsArgumentError);

      const invalidHigh = GenerationConfig(temperature: 1.1);
      expect(() => invalidHigh.validate(), throwsArgumentError);
    });

    test('should validate maxOutputTokens', () {
      const validConfig = GenerationConfig(maxOutputTokens: 100);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidConfig = GenerationConfig(maxOutputTokens: 0);
      expect(() => invalidConfig.validate(), throwsArgumentError);

      const negativeConfig = GenerationConfig(maxOutputTokens: -1);
      expect(() => negativeConfig.validate(), throwsArgumentError);
    });

    test('should validate topP range', () {
      const validConfig = GenerationConfig(topP: 0.5);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidLow = GenerationConfig(topP: -0.1);
      expect(() => invalidLow.validate(), throwsArgumentError);

      const invalidHigh = GenerationConfig(topP: 1.1);
      expect(() => invalidHigh.validate(), throwsArgumentError);
    });

    test('should validate topK', () {
      const validConfig = GenerationConfig(topK: 40);
      expect(() => validConfig.validate(), returnsNormally);

      const invalidConfig = GenerationConfig(topK: 0);
      expect(() => invalidConfig.validate(), throwsArgumentError);

      const negativeConfig = GenerationConfig(topK: -1);
      expect(() => negativeConfig.validate(), throwsArgumentError);
    });

    test('should validate stopSequences', () {
      const validConfig = GenerationConfig(stopSequences: ['STOP']);
      expect(() => validConfig.validate(), returnsNormally);

      const emptyConfig = GenerationConfig(stopSequences: []);
      expect(() => emptyConfig.validate(), throwsArgumentError);
    });

    test('should validate responseMimeType', () {
      const validConfig =
          GenerationConfig(responseMimeType: 'application/json');
      expect(() => validConfig.validate(), returnsNormally);

      const emptyConfig = GenerationConfig(responseMimeType: '');
      expect(() => emptyConfig.validate(), throwsArgumentError);
    });

    test('should implement equality correctly', () {
      const config1 = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
        stopSequences: ['STOP'],
      );

      const config2 = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
        stopSequences: ['STOP'],
      );

      const config3 = GenerationConfig(
        temperature: 0.5,
        maxOutputTokens: 1000,
        stopSequences: ['STOP'],
      );

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });

    test('should implement hashCode correctly', () {
      const config1 = GenerationConfig(temperature: 0.7);
      const config2 = GenerationConfig(temperature: 0.7);

      expect(config1.hashCode, equals(config2.hashCode));
    });

    test('should implement toString correctly', () {
      const config = GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 1000,
      );

      final string = config.toString();
      expect(string, contains('GenerationConfig'));
      expect(string, contains('temperature: 0.7'));
      expect(string, contains('maxOutputTokens: 1000'));
    });

    test('should handle null values in equality comparison', () {
      const config1 = GenerationConfig(stopSequences: null);
      const config2 = GenerationConfig(stopSequences: null);
      const config3 = GenerationConfig(stopSequences: ['STOP']);

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });
}
