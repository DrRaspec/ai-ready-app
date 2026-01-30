import 'dart:convert';

import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? status;
  final String? error;
  final Map<String, dynamic>? details;

  ApiException({required this.message, this.status, this.error, this.details});

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
        var data = response?.data;

        if (data is String) {
          try {
            data = data.isNotEmpty
                ? Map<String, dynamic>.from(json.decode(data) as Map)
                : null;
          } catch (_) {
            data = null;
          }
        }

        if (data is Map<String, dynamic>) {
          var message =
              (data['message'] as String?) ?? (data['error'] as String?) ?? '';
          Map<String, dynamic>? details;
          if (data['details'] is Map<String, dynamic>) {
            details = data['details'] as Map<String, dynamic>;
          } else if (data['details'] is List) {
            // Convert list of errors to a map with numeric keys
            final list = data['details'] as List;
            details = {
              for (var i = 0; i < list.length; i++) i.toString(): list[i],
            };
          }

          if (message.contains('Server returned HTTP response code:')) {
            message = 'Service temporarily unavailable (Protocol Error)';
          }

          return ApiException(
            message: message.isNotEmpty ? message : 'Server error occurred',
            status: response?.statusCode,
            error: data['error'] as String?,
            details: details,
          );
        }

        return ApiException(
          message: 'Server error occurred',
          status: response?.statusCode,
        );
      case DioExceptionType.cancel:
        return ApiException(message: 'Request cancelled', status: null);
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
          status: null,
        );
      default:
        final error = e.error;
        if (error is FormatException) {
          return ApiException(
            message:
                'Server returned an invalid response. Please try again later.',
            status: e.response?.statusCode,
            error: 'FormatException',
          );
        }
        return ApiException(
          message: e.message ?? 'An unexpected error occurred',
          status: e.response?.statusCode,
        );
    }
  }

  @override
  String toString() =>
      'ApiException(status: $status, message: $message, error: $error)';

  String getDetailedMessage() {
    if (message.isNotEmpty && message != 'Server error occurred') {
      return message;
    }

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
