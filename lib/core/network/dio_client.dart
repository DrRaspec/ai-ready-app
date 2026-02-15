import 'dart:async';

import 'package:ai_chat_bot/core/config/env_config.dart';
import 'package:ai_chat_bot/core/device/device_id_provider.dart';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:shadow_log/shadow_log.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  static const _retryAttemptKey = '_retry_attempted';
  static const Set<String> _publicPaths = {
    ApiPaths.login,
    ApiPaths.register,
    ApiPaths.googleLogin,
    ApiPaths.refreshToken,
  };

  late final Dio dio;
  final TokenStorage _tokenStorage;
  final DeviceIdProvider _deviceIdProvider;
  final Function()? onUnauthorized;

  Future<void>? _refreshFuture;

  DioClient({
    required TokenStorage tokenStorage,
    required DeviceIdProvider deviceIdProvider,
    this.onUnauthorized,
  }) : _tokenStorage = tokenStorage,
       _deviceIdProvider = deviceIdProvider {
    dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    // Add debug-only logger
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: false,
          responseBody: false,
          responseHeader: false,
          error: true,
          compact: true,
        ),
      );
    }

    // Debug-only error logger to reveal underlying socket or connection issues
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          if (kDebugMode) {
            final err = error.error;
            ShadowLog.d(
              'Dio error: type=${error.type} message=${error.message} '
              'url=${error.requestOptions.uri} errorType=${err.runtimeType} '
              'error=${err?.toString()}',
            );
            ShadowLog.e(
              'Dio error: type=${error.type} message=${error.message} '
              'url=${error.requestOptions.uri} error=${err?.toString()}',
              error: err,
              stackTrace: error.stackTrace,
            );
          }
          handler.next(error);
        },
      ),
    );

    // Add auth token interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isPublicEndpoint(options.path)) {
            options.headers.remove('Authorization');
            handler.next(options);
            return;
          }

          final token = await _tokenStorage.readAccessToken();
          if (token != null && token.isNotEmpty && token.trim().isNotEmpty) {
            options.headers['Authorization'] = 'Bearer ${token.trim()}';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final status = error.response?.statusCode;
          final requestOptions = error.requestOptions;
          final isPublicEndpoint = _isPublicEndpoint(requestOptions.path);
          final hasRetried = requestOptions.extra[_retryAttemptKey] == true;

          if (status == 401 && !isPublicEndpoint && !hasRetried) {
            final ok = await _tryRefreshToken();
            if (ok) {
              final newToken = await _tokenStorage.readAccessToken();
              if (newToken != null && newToken.trim().isNotEmpty) {
                requestOptions.headers['Authorization'] =
                    'Bearer ${newToken.trim()}';
              }
              requestOptions.extra[_retryAttemptKey] = true;

              try {
                final response = await dio.fetch(requestOptions);
                handler.resolve(response);
                return;
              } catch (_) {
                handler.next(error);
                return;
              }
            }

            await _tokenStorage.clear();
            onUnauthorized?.call();
          }

          handler.next(error);
        },
      ),
    );

    // Global interceptor to convert error status codes to responses
    // Since the API returns ApiResponse structure for all responses
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final res = error.response;
          // If we have a response body with the ApiResponse structure,
          // treat it as a successful response (not an exception)
          if (res?.statusCode != 401 &&
              res?.data is Map &&
              res!.data['success'] != null) {
            // Convert the error to a response so it can be parsed as ApiResponse
            handler.resolve(res);
            return;
          }
          // For other errors (network issues, etc.), keep as error
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    if (_refreshFuture != null) {
      await _refreshFuture;
      final token = await _tokenStorage.readAccessToken();
      return token != null && token.isNotEmpty;
    }

    final completer = Completer<void>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _tokenStorage.clear();
        return false;
      }

      // Direct refresh call to avoid circular dependency
      final response = await dio.post(
        ApiPaths.refreshToken,
        data: {
          'refreshToken': refreshToken,
          'deviceId': await _deviceIdProvider.getDeviceId(),
        },
      );

      final tokenData = _extractTokenPayload(response.data);
      final access = (tokenData['accessToken'] ?? tokenData['access_token'])
          ?.toString();
      final refresh = (tokenData['refreshToken'] ?? tokenData['refresh_token'])
          ?.toString();
      if (access != null && access.isNotEmpty) {
        await _tokenStorage.writeTokens(
          accessToken: access,
          refreshToken: refresh,
        );
        return true;
      }

      return false;
    } on DioException catch (e) {
      final api = e.error;
      if (api is ApiException && api.status == 401) {
        await _tokenStorage.clear();
      }
      return false;
    } catch (_) {
      await _tokenStorage.clear();
      return false;
    } finally {
      completer.complete();
      _refreshFuture = null;
    }
  }

  bool _isPublicEndpoint(String path) {
    final normalized = path.split('?').first;
    return _publicPaths.any(
      (publicPath) =>
          normalized == publicPath || normalized.endsWith(publicPath),
    );
  }

  Map<String, dynamic> _extractTokenPayload(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      return <String, dynamic>{};
    }

    final level1 = responseData['data'];
    if (level1 is Map<String, dynamic>) {
      final level2 = level1['data'];
      if (level2 is Map<String, dynamic>) {
        return level2;
      }
      return level1;
    }

    return responseData;
  }
}
