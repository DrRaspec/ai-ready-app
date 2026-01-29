import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:dio/dio.dart';

class PromptRepository {
  final DioClient _dioClient;

  PromptRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<List<Map<String, dynamic>>>> getPrompts() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.prompts);
      return ApiResponse<List<Map<String, dynamic>>>.fromJson(
        response.data,
        (json) => (json as List).cast<Map<String, dynamic>>(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> createPrompt(String title, String content) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.prompts,
        data: {'title': title, 'content': content},
      );
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<String>> enhancePrompt(String prompt) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.enhancePrompt,
        data: {'prompt': prompt},
      );
      // Assuming response is like { "success": true, "data": { "enhanced_prompt": "..." } }
      // Or just standard API response wrapping a string
      return ApiResponse<String>.fromJson(
        response.data,
        (json) => json['enhanced_prompt'] as String? ?? json.toString(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
