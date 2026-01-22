import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class DioLogger extends Interceptor {
  static const int _maxLength = 1000;
  bool get _enabled => kDebugMode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (_enabled) {
      log('REQUEST: ${options.method} ${options.uri}');
      log('Headers: ${options.headers}');
      log('Query: ${options.queryParameters}');
      log('Body: ${_pretty(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_enabled) {
      log('RESPONSE [${response.statusCode}]: ${response.requestOptions.uri}');
      log('Data: ${_pretty(response.data)}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_enabled) {
      log(
        'ERROR [${err.response?.statusCode ?? 'N/A'}]: ${err.requestOptions.uri}',
      );
      log('Data: ${_pretty(err.response?.data)}');
      log('Message: ${err.message}');
    }
    handler.next(err);
  }

  String _pretty(dynamic data) {
    if (data == null) return 'null';
    try {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      return jsonStr.length > _maxLength
          ? '${jsonStr.substring(0, _maxLength)}...'
          : jsonStr;
    } catch (_) {
      return data.toString();
    }
  }
}
