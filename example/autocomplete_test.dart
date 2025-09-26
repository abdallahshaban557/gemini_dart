import 'package:gemini_dart/src/models/gemini_config.dart';

void main() {
  // When you type ApiVersion. in your IDE, you should see auto-complete suggestions for:
  // - ApiVersion.v1
  // - ApiVersion.v1beta

  const config1 = GeminiConfig(
    apiVersion: ApiVersion.v1, // Auto-complete should suggest v1 and v1beta
  );

  const config2 = GeminiConfig(
    apiVersion: ApiVersion.v1beta, // Auto-complete should suggest v1 and v1beta
  );

  print('Config 1 API version: ${config1.apiVersion.value}');
  print('Config 2 API version: ${config2.apiVersion.value}');

  // You can also access the enum values directly
  print('Available API versions:');
  for (final version in ApiVersion.values) {
    print('  - ${version.value}');
  }
}
