import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;

  RetryInterceptor({required this.dio, this.maxRetries = 3});

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isGetRequest = err.requestOptions.method.toUpperCase() == 'GET';

    final isNetworkOrServerError = 
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response != null && err.response!.statusCode! >= 500);

    if (isGetRequest && isNetworkOrServerError) {
      int retryCount = err.requestOptions.extra['retry_count'] ?? 0;

      if (retryCount < maxRetries) {
        retryCount++;
        err.requestOptions.extra['retry_count'] = retryCount;

        final delay = Duration(seconds: retryCount);
        await Future.delayed(delay);

        try {
          final response = await dio.fetch(err.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          if (e is DioException) {
            return super.onError(e, handler);
          }
        }
      }
    }

    return super.onError(err, handler);
  }
}