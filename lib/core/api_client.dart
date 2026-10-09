import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; 
import '../state/auth_provider.dart';
import 'api_exceptions.dart';
import 'retry_interceptor.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api',
);

Dio buildDio(AuthProvider authProvider) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(RetryInterceptor(dio: dio, maxRetries: 3));

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = authProvider.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        if (kDebugMode) {
          debugPrint('[API] -> ${options.method} ${options.uri}');
        }
        
        return handler.next(options);
      },
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[API] <- ${response.statusCode} ${response.requestOptions.uri}');
        }

        final status = response.statusCode ?? 0;

        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true, 
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        final status = error.response?.statusCode;

        if (status == 401 && !error.requestOptions.path.contains('/auth/')) {
          try {
            await authProvider.refreshTokens();

            final options = error.requestOptions;
            options.headers['Authorization'] = 'Bearer ${authProvider.accessToken}';

            final retryDio = Dio(dio.options);
            final response = await retryDio.fetch(options);
            
            return handler.resolve(response);
          } catch (_) {
            await authProvider.logout();
            return handler.reject(error);
          }
        }

        if (kDebugMode) {
          debugPrint('[API] ОШИБКА ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}