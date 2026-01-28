import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../service/batteryGate.dart';

class ApiClient {
  final Dio dio;

  ApiClient({required String baseUrl, required BatteryGate batteryGate})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'X-API-KEY': dotenv.env['API_KEY']!,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (!batteryGate.networkAllowed) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: 'Battery critical: network disabled',
              ),
            );
          }
          return handler.next(options);
        },
      ),
    );
  }
}
