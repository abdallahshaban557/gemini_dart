import 'exceptions.dart';
import 'secure_storage.dart';

/// Authentication handler for managing API keys and authentication
class AuthenticationHandler {
  AuthenticationHandler({SecureStorageInterface? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorage();
  String? _apiKey;
  final SecureStorageInterface _secureStorage;

  /// Sets the API key for authentication
  void setApiKey(String apiKey) {
    if (apiKey.isEmpty) {
      throw const GeminiAuthException('API key cannot be empty');
    }
    _apiKey = apiKey;
  }

  /// Gets the current API key
  String? get apiKey => _apiKey;

  /// Validates the API key format
  bool validateApiKey(String apiKey) {
    if (apiKey.isEmpty) return false;

    // Basic validation - Gemini API keys typically start with 'AIza'
    if (!apiKey.startsWith('AIza')) return false;

    // Check minimum length (Gemini API keys are typically 39 characters)
    if (apiKey.length < 30) return false;

    return true;
  }

  /// Stores API key securely
  Future<void> storeApiKey(String apiKey) async {
    if (!validateApiKey(apiKey)) {
      throw GeminiAuthException('Invalid API key format');
    }

    await _secureStorage.store('gemini_api_key', apiKey);
    _apiKey = apiKey;
  }

  /// Retrieves stored API key
  Future<String?> retrieveStoredApiKey() async {
    final storedKey = await _secureStorage.retrieve('gemini_api_key');
    if (storedKey != null) {
      _apiKey = storedKey;
    }
    return storedKey;
  }

  /// Clears stored API key
  Future<void> clearStoredApiKey() async {
    await _secureStorage.delete('gemini_api_key');
    _apiKey = null;
  }

  /// Gets authentication headers for API requests
  Map<String, String> getAuthHeaders() {
    if (_apiKey == null) {
      throw GeminiAuthException('API key not set. Call setApiKey() first.');
    }

    return {
      'x-goog-api-key': _apiKey!,
      'Content-Type': 'application/json',
    };
  }

  /// Checks if authentication is configured
  bool get isAuthenticated => _apiKey != null && _apiKey!.isNotEmpty;
}
