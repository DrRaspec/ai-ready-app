import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:dio/dio.dart';

class AnalyticsRepository {
  final DioClient _dioClient;

  AnalyticsRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<List<Map<String, dynamic>>>> getUsageAnalytics() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.analyticsUsage);
      return ApiResponse<List<Map<String, dynamic>>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
