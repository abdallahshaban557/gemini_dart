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

@GenerateMocks([http.Client])
import 'http_service_simple_test.mocks.dart';

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

  group('HttpService Basic Tests', () {
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
  });

  group('HttpService Retry Tests', () {
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
      // Create a new retry service with logging enabled to debug
      final debugConfig = config.copyWith(enableLogging: true);
      final debugRetryService = HttpService(
        auth: auth,
        config: debugConfig,
        retryConfig: const RetryConfig(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
        ),
        client: mockClient,
      );

      var callCount = 0;
      when(mockClient.get(any, headers: anyNamed('headers')))
          .thenAnswer((_) async {
        callCount++;
        print('HTTP call $callCount');
        throw const SocketException('Connection failed');
      });

      try {
        await debugRetryService.get('test');
        fail('Expected exception');
      } catch (e) {
        print('Final exception: ${e.runtimeType}');
        expect(e, isA<GeminiNetworkException>());
      }

      print('Total calls made: $callCount');
      expect(callCount, equals(3));

      debugRetryService.dispose();
    });
  });
}
