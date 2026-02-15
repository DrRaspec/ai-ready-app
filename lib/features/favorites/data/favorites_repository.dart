import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:dio/dio.dart';

class FavoritesRepository {
  final DioClient _dioClient;

  FavoritesRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<Map<String, dynamic>?>> toggleFavorite({
    required String targetType,
    required String targetId,
    String? note,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.favoritesToggle,
        data: {
          'targetType': targetType,
          'targetId': targetId,
          if (note != null) 'note': note,
        },
      );
      return ApiResponse<Map<String, dynamic>?>.fromJson(response.data, (json) {
        if (json == null) return null;
        return Map<String, dynamic>.from(json as Map);
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getFavorites() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.favorites);
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
