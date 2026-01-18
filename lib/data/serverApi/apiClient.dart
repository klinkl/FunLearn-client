import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      ) {
    dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
