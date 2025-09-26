import 'package:gemini_dart/src/models/gemini_config.dart';

void main() {
  // Example 1: Using the default API version (v1)
  const defaultConfig = GeminiConfig();
  print('Default API version: ${defaultConfig.apiVersion.value}');

  // Example 2: Explicitly setting API version to v1
  const v1Config = GeminiConfig(
    apiVersion: ApiVersion.v1,
  );
  print('V1 API version: ${v1Config.apiVersion.value}');

  // Example 3: Using the beta API version
  const betaConfig = GeminiConfig(
    apiVersion: ApiVersion.v1beta,
  );
  print('Beta API version: ${betaConfig.apiVersion.value}');

  // Example 4: JSON serialization/deserialization
  final configJson = betaConfig.toJson();
  print('Serialized API version: ${configJson['apiVersion']}');

  final deserializedConfig = GeminiConfig.fromJson(configJson);
  print('Deserialized API version: ${deserializedConfig.apiVersion.value}');

  // Example 5: Validation
  try {
    defaultConfig.validate();
    print('Default config is valid');
  } catch (e) {
    print('Validation error: $e');
  }

  // Example 6: Using copyWith
  final modifiedConfig = defaultConfig.copyWith(
    apiVersion: ApiVersion.v1beta,
  );
  print('Modified API version: ${modifiedConfig.apiVersion.value}');
}
