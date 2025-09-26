import '../models/gemini_config.dart';
import 'auth.dart';
import 'config_validator.dart';
import 'exceptions.dart';

/// Manages configuration and authentication for the Gemini client
class ConfigurationManager {
  final AuthenticationHandler _authHandler;
  GeminiConfig _config;

  ConfigurationManager({
    GeminiConfig? config,
    AuthenticationHandler? authHandler,
  })  : _config = ConfigValidator.mergeWithDefaults(config),
        _authHandler = authHandler ?? AuthenticationHandler();

  /// Gets the current configuration
  GeminiConfig get config => _config;

  /// Gets the authentication handler
  AuthenticationHandler get auth => _authHandler;

  /// Updates the configuration with validation
  void updateConfig(GeminiConfig newConfig) {
    ConfigValidator.validateConfig(newConfig);
    _config = newConfig;
  }

  /// Initializes the configuration manager with API key
  Future<void> initialize(String apiKey, {GeminiConfig? config}) async {
    // Update config if provided
    if (config != null) {
      updateConfig(config);
    }

    // Set up authentication
    _authHandler.setApiKey(apiKey);

    // Optionally store the API key securely
    if (_config.enableLogging) {
      // Only store if logging is enabled (indicates development/debug mode)
      await _authHandler.storeApiKey(apiKey);
    }
  }

  /// Initializes from stored credentials
  Future<bool> initializeFromStorage() async {
    final storedKey = await _authHandler.retrieveStoredApiKey();
    if (storedKey != null) {
      _authHandler.setApiKey(storedKey);
      return true;
    }
    return false;
  }

  /// Gets authentication headers for API requests
  Map<String, String> getRequestHeaders() {
    final headers = _authHandler.getAuthHeaders();

    // Add additional headers based on configuration
    headers.addAll({
      'User-Agent': 'gemini-dart/${_getPackageVersion()}',
      'Accept': 'application/json',
    });

    return headers;
  }

  /// Validates the current configuration and authentication
  void validate() {
    ConfigValidator.validateConfig(_config);

    if (!_authHandler.isAuthenticated) {
      throw GeminiAuthException(
        'Authentication not configured. Call initialize() with an API key.',
      );
    }
  }

  /// Clears stored credentials and resets configuration
  Future<void> reset() async {
    await _authHandler.clearStoredApiKey();
    _config = ConfigValidator.createDefaultConfig();
  }

  /// Gets the base URL for API requests
  String get baseUrl => _config.baseUrl;

  /// Gets the API version
  String get apiVersion => _config.apiVersion.value;

  /// Gets the full API endpoint URL
  String getApiEndpoint(String path) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '${_config.baseUrl}/${_config.apiVersion.value}/$cleanPath';
  }

  /// Checks if the configuration is ready for API calls
  bool get isReady => _authHandler.isAuthenticated;

  /// Gets package version (placeholder for actual version)
  String _getPackageVersion() {
    // In a real implementation, this would read from pubspec.yaml
    return '0.1.0';
  }
}
