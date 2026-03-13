/// Lightweight internet reachability checks for cloud AI routing.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

class NetworkStatusService {
  static final NetworkStatusService _instance =
      NetworkStatusService._internal();

  factory NetworkStatusService() => _instance;

  NetworkStatusService._internal();

  final Connectivity _connectivity = Connectivity();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 3),
      receiveTimeout: const Duration(seconds: 3),
      responseType: ResponseType.plain,
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  Future<bool> hasInternetConnection() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final hasTransport = connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasTransport) {
      return false;
    }

    try {
      final response = await _dio.getUri(
        Uri.parse('https://clients3.google.com/generate_204'),
      );
      final statusCode = response.statusCode ?? 0;
      return statusCode == 204 || (statusCode >= 200 && statusCode < 400);
    } on DioException {
      return false;
    }
  }
}
