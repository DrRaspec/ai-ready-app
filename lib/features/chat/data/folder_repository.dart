import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/folder.dart';
import 'package:dio/dio.dart';

class FolderRepository {
  final DioClient _dioClient;

  FolderRepository(DioClient dioClient) : _dioClient = dioClient;

  /// Get all folders
  Future<ApiResponse<List<Folder>>> getFolders() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.folders);
      final data = response.data;
      if (data is List) {
        return ApiResponse<List<Folder>>(
          success: true,
          message: 'Folders loaded successfully',
          status: 200,
          data: data
              .map((e) => Folder.fromJson(e as Map<String, dynamic>))
              .toList(),
        );
      }

      return ApiResponse<List<Folder>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((e) => Folder.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Create a folder
  Future<ApiResponse<Folder>> createFolder(
    String name, {
    String? parentId,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.folders,
        data: {'name': name, if (parentId != null) 'parentId': parentId},
      );
      return ApiResponse<Folder>.fromJson(
        response.data,
        (json) => Folder.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update folder name
  Future<ApiResponse<Folder>> updateFolder(String id, String name) async {
    try {
      final response = await _dioClient.dio.put(
        ApiPaths.folder(id),
        data: {'name': name},
      );
      return ApiResponse<Folder>.fromJson(
        response.data,
        (json) => Folder.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete a folder
  Future<ApiResponse<void>> deleteFolder(String id) async {
    try {
      final response = await _dioClient.dio.delete(ApiPaths.folder(id));
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
