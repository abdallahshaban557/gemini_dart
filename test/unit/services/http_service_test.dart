import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../../lib/src/core/auth.dart';
import '../../../lib/src/core/exceptions.dart';
import '../../../lib/src/core/retry_config.dart';
import '../../../lib/src/models/gemini_config.dart';
import '../../../lib/src/services/http_service.dart';

import 'http_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  late MockClient mockClient;
  late AuthenticationHandler auth;
  late GeminiConfig config;
  late HttpService httpService;

  setUp(() {
    mockClient = MockClient();
    auth = AuthenticationHandler();
    auth.setApiKey('test-api-key');
    config = const GeminiConfig(
      baseUrl: 'https://api.example.com',
      apiVersion: ApiVersion.v1,
      timeout: Duration(seconds: 10),
    );

    httpService = HttpService(
      auth: auth,
      config: config,
      retryConfig: const RetryConfig.noRetry(),
      client: mockClient,
    );
  });

  tearDown(() {
    httpService.dispose();
  });

  group('HttpService', () {
    group('constructor', () {
      test('should create with default retry config when not provided', () {
        final service = HttpService(
          auth: auth,
          config: config,
          client: mockClient,
        );
        expect(service, isNotNull);
        service.dispose();
      });

      test('should validate config on creation', () {
        final invalidConfig = const GeminiConfig(baseUrl: '');
        expect(
          () => HttpService(
            auth: auth,
            config: invalidConfig,
            client: mockClient,
          ),
          throwsArgumentError,
        );
      });
    });

    group('GET requests', () {
      test('should make successful GET request', () async {
        final responseBody = {'message': 'success'};
        final response = http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json'},
        );

        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        final result = await httpService.get('test-endpoint');

        expect(result, equals(responseBody));
        verify(mockClient.get(
          Uri.parse('https://api.example.com/v1/test-endpoint'),
          headers: argThat(
            containsPair('x-goog-api-key', 'test-api-key'),
            named: 'headers',
          ),
        )).called(1);
      });

      test('should include query parameters in GET request', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('test', queryParameters: {'param1': 'value1'});

        verify(mockClient.get(
          Uri.parse('https://api.example.com/v1/test?param1=value1'),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should include custom headers in GET request', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService
            .get('test', headers: {'Custom-Header': 'custom-value'});

        verify(mockClient.get(
          any,
          headers: argThat(
            allOf([
              containsPair('x-goog-api-key', 'test-api-key'),
              containsPair('Custom-Header', 'custom-value'),
            ]),
            named: 'headers',
          ),
        )).called(1);
      });
    });

    group('POST requests', () {
      test('should make successful POST request with body', () async {
        final requestBody = {'input': 'test'};
        final responseBody = {'output': 'result'};
        final response = http.Response(jsonEncode(responseBody), 200);

        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => response);

        final result = await httpService.post('test', body: requestBody);

        expect(result, equals(responseBody));
        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: jsonEncode(requestBody),
        )).called(1);
      });

      test('should make POST request without body', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => response);

        await httpService.post('test');

        verify(mockClient.post(
          any,
          headers: anyNamed('headers'),
          body: null,
        )).called(1);
      });
    });

    group('PUT requests', () {
      test('should make successful PUT request', () async {
        final requestBody = {'data': 'update'};
        final response = http.Response('{"updated": true}', 200);

        when(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => response);

        final result = await httpService.put('test', body: requestBody);

        expect(result, equals({'updated': true}));
        verify(mockClient.put(
          any,
          headers: anyNamed('headers'),
          body: jsonEncode(requestBody),
        )).called(1);
      });
    });

    group('DELETE requests', () {
      test('should make successful DELETE request', () async {
        final response = http.Response('{"deleted": true}', 200);
        when(mockClient.delete(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        final result = await httpService.delete('test');

        expect(result, equals({'deleted': true}));
        verify(mockClient.delete(any, headers: anyNamed('headers'))).called(1);
      });
    });

    group('PATCH requests', () {
      test('should make successful PATCH request', () async {
        final requestBody = {'field': 'new_value'};
        final response = http.Response('{"patched": true}', 200);

        when(mockClient.patch(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => response);

        final result = await httpService.patch('test', body: requestBody);

        expect(result, equals({'patched': true}));
        verify(mockClient.patch(
          any,
          headers: anyNamed('headers'),
          body: jsonEncode(requestBody),
        )).called(1);
      });
    });

    group('error handling', () {
      test('should throw GeminiAuthException when auth fails', () async {
        // Create a service with no API key set
        final authWithoutKey = AuthenticationHandler();
        final serviceWithoutAuth = HttpService(
          auth: authWithoutKey,
          config: config,
          retryConfig: const RetryConfig.noRetry(),
          client: mockClient,
        );

        expect(
          () => serviceWithoutAuth.get('test'),
          throwsA(isA<GeminiAuthException>()),
        );
      });

      test('should throw GeminiValidationException for 400 status', () async {
        final response =
            http.Response('{"error": {"message": "Bad request"}}', 400);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should throw GeminiAuthException for 401 status', () async {
        final response =
            http.Response('{"error": {"message": "Unauthorized"}}', 401);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiAuthException>()),
        );
      });

      test('should throw GeminiRateLimitException for 429 status', () async {
        final response =
            http.Response('{"error": {"message": "Rate limited"}}', 429);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiRateLimitException>()),
        );
      });

      test('should throw GeminiServerException for 500 status', () async {
        final response =
            http.Response('{"error": {"message": "Server error"}}', 500);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiServerException>()),
        );
      });

      test('should throw GeminiValidationException for invalid JSON response',
          () async {
        final response = http.Response('invalid json', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiValidationException>()),
        );
      });

      test('should throw GeminiTimeoutException on timeout', () async {
        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
            (_) async => throw TimeoutException(
                'Request timed out', const Duration(seconds: 10)));

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiTimeoutException>()),
        );
      });

      test('should throw GeminiNetworkException on SocketException', () async {
        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
            (_) async => throw const SocketException('Connection failed'));

        expect(
          () => httpService.get('test'),
          throwsA(isA<GeminiNetworkException>()),
        );
      });
    });

    group('retry mechanism', () {
      late HttpService retryService;

      setUp(() {
        retryService = HttpService(
          auth: auth,
          config: config,
          retryConfig: const RetryConfig(
            maxAttempts: 3,
            initialDelay: Duration(milliseconds: 10),
          ),
          client: mockClient,
        );
      });

      tearDown(() {
        retryService.dispose();
      });

      test('should retry on retryable exceptions', () async {
        var callCount = 0;
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount <= 2) {
            throw const SocketException('Connection failed');
          } else {
            return http.Response('{"success": true}', 200);
          }
        });

        final result = await retryService.get('test');

        expect(result, equals({'success': true}));
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(3);
      });

      test('should not retry on non-retryable exceptions', () async {
        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
            (_) async => http.Response('{"error": "Unauthorized"}', 401));

        expect(
          () => retryService.get('test'),
          throwsA(isA<GeminiAuthException>()),
        );
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should exhaust retries and throw last exception', () async {
        // Track call count manually
        int callCount = 0;
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          callCount++;
          throw const SocketException('Connection failed');
        });

        try {
          await retryService.get('test');
          fail('Expected exception to be thrown');
        } catch (e) {
          expect(e, isA<GeminiNetworkException>());
          expect(callCount, equals(3),
              reason: 'Should make 3 attempts (1 initial + 2 retries)');
        }
      });

      test('should handle rate limit delays', () async {
        final rateLimitResponse = http.Response(
          '{"error": {"message": "Rate limited", "retry_after": 1}}',
          429,
        );

        var callCount = 0;
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            return rateLimitResponse;
          } else {
            return http.Response('{"success": true}', 200);
          }
        });

        final result = await retryService.get('test');

        expect(result, equals({'success': true}));
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(2);
      });
    });

    group('URI building', () {
      test('should build correct URI with base URL and endpoint', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('models/gemini-pro');

        verify(mockClient.get(
          Uri.parse('https://api.example.com/v1/models/gemini-pro'),
          headers: anyNamed('headers'),
        )).called(1);
      });

      test('should handle double slashes in path', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('/models/gemini-pro');

        verify(mockClient.get(
          Uri.parse('https://api.example.com/v1/models/gemini-pro'),
          headers: anyNamed('headers'),
        )).called(1);
      });
    });

    group('headers', () {
      test('should include default headers', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('test');

        verify(mockClient.get(
          any,
          headers: argThat(
            allOf([
              containsPair('User-Agent', 'gemini-dart/0.1.0'),
              containsPair('Accept', 'application/json'),
              containsPair('x-goog-api-key', 'test-api-key'),
              containsPair('Content-Type', 'application/json'),
            ]),
            named: 'headers',
          ),
        )).called(1);
      });

      test('should merge custom headers with defaults', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('test', headers: {'Custom-Header': 'value'});

        verify(mockClient.get(
          any,
          headers: argThat(
            allOf([
              containsPair('User-Agent', 'gemini-dart/0.1.0'),
              containsPair('Custom-Header', 'value'),
              containsPair('x-goog-api-key', 'test-api-key'),
            ]),
            named: 'headers',
          ),
        )).called(1);
      });

      test('should allow custom headers to override defaults', () async {
        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await httpService.get('test', headers: {'Accept': 'text/plain'});

        verify(mockClient.get(
          any,
          headers: argThat(
            containsPair('Accept', 'text/plain'),
            named: 'headers',
          ),
        )).called(1);
      });
    });

    group('logging', () {
      test('should log requests when logging is enabled', () async {
        final loggingConfig = config.copyWith(enableLogging: true);
        final loggingService = HttpService(
          auth: auth,
          config: loggingConfig,
          retryConfig: const RetryConfig.noRetry(),
          client: mockClient,
        );

        final response = http.Response('{"result": "ok"}', 200);
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => response);

        await loggingService.get('test');

        // Note: In a real test, you'd capture stdout or use a logging framework
        // This test just ensures the logging code path is exercised
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);

        loggingService.dispose();
      });
    });
  });
}
