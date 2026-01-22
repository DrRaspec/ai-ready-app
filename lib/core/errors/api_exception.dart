import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? error;
  final Map<String, dynamic>? details;

  ApiException({
    required this.message,
    this.status,
    this.error,
    this.details,
  });

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          status: null,
        );
      case DioExceptionType.badResponse:
        final response = e.response;
        final data = response?.data;
        
        if (data is Map<String, dynamic>) {
          return ApiException(
            message: data['message'] as String? ?? 'Server error occurred',
            status: response?.statusCode,
            error: data['error'] as String?,
            details: data['details'] as Map<String, dynamic>?,
          );
        }
        
        return ApiException(
          message: 'Server error occurred',
          status: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
          status: null,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          status: null,
        );
      default:
        return ApiException(
          message: e.message ?? 'An unexpected error occurred',
          status: null,
        );
    }
  }

  @override
  String toString() =>
      'ApiException(status: $status, message: $message, error: $error)';

  String getDetailedMessage() {
    if (details != null && details!.isNotEmpty) {
      final firstError = details!.values.first;
      if (firstError is String) {
        return firstError;
      } else if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
    }
    return message;
  }
}