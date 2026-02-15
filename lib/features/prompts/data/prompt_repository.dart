import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:dio/dio.dart';

class PromptRepository {
  final DioClient _dioClient;

  PromptRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<List<Map<String, dynamic>>>> getPrompts({
    bool fromTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        fromTemplates ? ApiPaths.promptTemplates : ApiPaths.prompts,
      );
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

  Future<ApiResponse<List<Map<String, dynamic>>>> searchPrompts(
    String query, {
    bool fromTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        fromTemplates
            ? ApiPaths.promptTemplatesSearch
            : '${ApiPaths.prompts}/search',
        queryParameters: {fromTemplates ? 'q' : 'query': query},
      );

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

  Future<ApiResponse<Map<String, dynamic>>> getPromptById(
    String id, {
    bool fromTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        fromTemplates ? ApiPaths.promptTemplate(id) : ApiPaths.prompt(id),
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => Map<String, dynamic>.from(json as Map),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> createPrompt(
    String name,
    String content, {
    String? description,
    String? category,
    bool isPublic = false,
    bool toTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        toTemplates ? ApiPaths.promptTemplates : ApiPaths.prompts,
        data: {
          'name': name,
          'content': content,
          if (description != null) 'description': description,
          if (category != null) 'category': category,
          'isPublic': isPublic,
        },
      );
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> updatePrompt(
    String id, {
    required String name,
    required String content,
    String? description,
    String? category,
    bool isPublic = false,
    bool inTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        inTemplates ? ApiPaths.promptTemplate(id) : ApiPaths.prompt(id),
        data: {
          'name': name,
          'content': content,
          if (description != null) 'description': description,
          if (category != null) 'category': category,
          'isPublic': isPublic,
        },
      );
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> deletePrompt(
    String id, {
    bool fromTemplates = false,
  }) async {
    try {
      final response = await _dioClient.dio.delete(
        fromTemplates ? ApiPaths.promptTemplate(id) : ApiPaths.prompt(id),
      );
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<String>> usePrompt(
    String id, {
    bool fromTemplates = false,
  }) async {
    try {
      final base = fromTemplates ? ApiPaths.promptTemplates : ApiPaths.prompts;
      final response = await _dioClient.dio.post('$base/$id/use');

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return (json['content'] ?? json['prompt'] ?? '').toString();
        }
        return json?.toString() ?? '';
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<String>> enhancePrompt(String prompt) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.enhancePrompt,
        queryParameters: {'prompt': prompt},
      );
      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return (json['enhancedPrompt'] ?? json['enhanced_prompt'] ?? '')
              .toString();
        }
        return json.toString();
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
