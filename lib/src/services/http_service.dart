import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import '../core/auth.dart';
import '../core/exceptions.dart';
import '../core/retry_config.dart';
import '../models/gemini_config.dart';

/// HTTP service for making requests to the Gemini API
class HttpService {
  final http.Client _client;
  final AuthenticationHandler _auth;
  final GeminiConfig _config;
  final RetryConfig _retryConfig;

  /// Creates a new HttpService
  HttpService({
    required AuthenticationHandler auth,
    required GeminiConfig config,
    RetryConfig? retryConfig,
    http.Client? client,
  })  : _auth = auth,
        _config = config,
        _retryConfig = retryConfig ?? const RetryConfig(),
        _client = client ?? http.Client() {
    _config.validate();
    _retryConfig.validate();
  }

  /// Makes a GET request to the specified endpoint
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);

    return _executeWithRetry(() async {
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(_config.timeout);

      return _handleResponse(response);
    });
  }

  /// Makes a POST request to the specified endpoint
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    return _executeWithRetry(() async {
      final response = await _client
          .post(uri, headers: requestHeaders, body: requestBody)
          .timeout(_config.timeout);

      return _handleResponse(response);
    });
  }

  /// Makes a PUT request to the specified endpoint
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    return _executeWithRetry(() async {
      final response = await _client
          .put(uri, headers: requestHeaders, body: requestBody)
          .timeout(_config.timeout);

      return _handleResponse(response);
    });
  }

  /// Makes a DELETE request to the specified endpoint
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);

    return _executeWithRetry(() async {
      final response = await _client
          .delete(uri, headers: requestHeaders)
          .timeout(_config.timeout);

      return _handleResponse(response);
    });
  }

  /// Makes a PATCH request to the specified endpoint
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    return _executeWithRetry(() async {
      final response = await _client
          .patch(uri, headers: requestHeaders, body: requestBody)
          .timeout(_config.timeout);

      return _handleResponse(response);
    });
  }

  /// Makes a streaming POST request for real-time responses
  Stream<Map<String, dynamic>> postStream(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async* {
    final uri = _buildUri(endpoint, queryParameters);
    final requestHeaders = _buildHeaders(headers);
    final requestBody = body != null ? jsonEncode(body) : null;

    // Add streaming headers
    requestHeaders['Accept'] = 'text/event-stream';
    requestHeaders['Cache-Control'] = 'no-cache';

    final request = http.Request('POST', uri);
    request.headers.addAll(requestHeaders);
    if (requestBody != null) {
      request.body = requestBody;
    }

    try {
      final streamedResponse =
          await _client.send(request).timeout(_config.timeout);

      if (streamedResponse.statusCode >= 400) {
        final responseBody = await streamedResponse.stream.bytesToString();
        throw ExceptionMapper.mapStatusCode(
          streamedResponse.statusCode,
          'Stream request failed',
          responseBody: responseBody,
        );
      }

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        // Parse Server-Sent Events format
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isNotEmpty && data != '[DONE]') {
              try {
                final json = jsonDecode(data) as Map<String, dynamic>;
                yield json;
              } catch (e) {
                if (_config.enableLogging) {
                  print('Failed to parse streaming data: $data');
                }
                // Continue processing other chunks
              }
            }
          }
        }
      }
    } on TimeoutException catch (e) {
      throw GeminiTimeoutException(
        'Stream request timed out',
        _config.timeout,
        originalError: e,
      );
    } catch (e) {
      throw ExceptionMapper.mapHttpException(e);
    }
  }

  /// Uploads a file using multipart form data
  Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String? fieldName,
    String? mimeType,
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
    void Function(int sent, int total)? onProgress,
  }) async {
    final uri = _buildUri(endpoint);
    final requestHeaders = _buildHeaders(headers);

    return _executeWithRetry(() async {
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(requestHeaders);

      // Add the file
      final multipartFile = await http.MultipartFile.fromPath(
        fieldName ?? 'file',
        file.path,
        contentType:
            mimeType != null ? http_parser.MediaType.parse(mimeType) : null,
      );
      request.files.add(multipartFile);

      // Add additional fields
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      final streamedResponse =
          await _client.send(request).timeout(_config.timeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    });
  }

  /// Builds the complete URI for a request
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final baseUri = Uri.parse(_config.baseUrl);
    final path = '${baseUri.path}/${_config.apiVersion.value}/$endpoint'
        .replaceAll('//', '/');

    return baseUri.replace(
      path: path,
      queryParameters: queryParameters,
    );
  }

  /// Builds request headers including authentication
  Map<String, String> _buildHeaders([Map<String, String>? additionalHeaders]) {
    final headers = <String, String>{
      'User-Agent': 'gemini-dart/0.1.0',
      'Accept': 'application/json',
      ...?additionalHeaders,
    };

    // Add authentication headers
    try {
      headers.addAll(_auth.getAuthHeaders());
    } catch (e) {
      throw GeminiAuthException(
        'Authentication not configured: ${e.toString()}',
        originalError: e,
      );
    }

    return headers;
  }

  /// Handles HTTP response and converts to JSON
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (_config.enableLogging) {
      print(
          'HTTP ${response.request?.method} ${response.request?.url} -> ${response.statusCode}');
    }

    if (response.statusCode >= 400) {
      String message = 'HTTP ${response.statusCode}';
      try {
        final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        message = errorBody['error']?['message'] ?? message;
      } catch (_) {
        // Use default message if JSON parsing fails
      }

      throw ExceptionMapper.mapStatusCode(
        response.statusCode,
        message,
        responseBody: response.body,
      );
    }

    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw GeminiValidationException(
        'Failed to parse response JSON: ${e.toString()}',
        {},
        originalError: e,
      );
    }
  }

  /// Executes a request with retry logic
  Future<T> _executeWithRetry<T>(Future<T> Function() operation) async {
    int attemptNumber = 0;
    dynamic lastException;

    while (attemptNumber < _retryConfig.maxAttempts) {
      attemptNumber++;

      try {
        return await operation();
      } on TimeoutException catch (e) {
        lastException = GeminiTimeoutException(
          'Request timed out after ${_config.timeout}',
          _config.timeout,
          originalError: e,
        );
      } catch (e) {
        lastException =
            e is GeminiException ? e : ExceptionMapper.mapHttpException(e);
      }

      // Check if we should retry
      if (!_retryConfig.shouldRetry(lastException, attemptNumber)) {
        break;
      }

      // Calculate delay
      Duration delay;
      if (lastException is GeminiRateLimitException) {
        delay = _retryConfig.getRateLimitDelay(lastException);
      } else {
        delay = _retryConfig.calculateDelay(attemptNumber);
      }

      if (_config.enableLogging) {
        print(
            'Retry attempt $attemptNumber after ${delay.inMilliseconds}ms: ${lastException.toString()}');
      }

      // Wait before retrying
      if (delay > Duration.zero) {
        await Future.delayed(delay);
      }
    }

    // All retries exhausted, throw the last exception
    throw lastException;
  }

  /// Disposes the HTTP client
  void dispose() {
    _client.close();
  }
}
