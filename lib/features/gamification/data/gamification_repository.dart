import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/gamification/data/models/gamification_status.dart';
import 'package:ai_chat_bot/features/gamification/data/models/usage_stats.dart';
import 'package:dio/dio.dart';

class GamificationRepository {
  final DioClient _dioClient;

  GamificationRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<GamificationStatus>> getStatus() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.gamificationStatus);

      return ApiResponse<GamificationStatus>.fromJson(
        response.data,
        (json) => GamificationStatus.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<UsageStats>> getUsageStats() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.usage);

      return ApiResponse<UsageStats>.fromJson(
        response.data,
        (json) => UsageStats.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
