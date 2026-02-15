import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:dio/dio.dart';

class HealthRepository {
  final DioClient _dioClient;

  HealthRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<Map<String, dynamic>> health() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.health);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> live() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.healthLive);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Map<String, dynamic>> ready() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.healthReady);
      return Map<String, dynamic>.from(response.data as Map);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
