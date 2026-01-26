import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/features/chat/data/models/usage_summary.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(DioClient dioClient) : _dioClient = dioClient;

  /// Send a new chat message (creates new conversation).
  Future<ApiResponse<ChatResponse>> sendMessage(ChatRequest request) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.chat,
        data: request.toJson(),
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Send a message to an existing conversation.
  Future<ApiResponse<ChatResponse>> sendMessageToConversation(
    String conversationId,
    ChatRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.chatWithConversation(conversationId),
        data: request.toJson(),
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get paginated list of conversations.
  Future<ApiResponse<List<Conversation>>> getConversations({
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.conversations,
        queryParameters: {'page': page, 'size': size},
      );

      return ApiResponse<List<Conversation>>.fromJson(response.data, (json) {
        // Handle paged response
        if (json is Map && json['content'] != null) {
          return (json['content'] as List)
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        // Handle direct list
        if (json is List) {
          return json
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get messages for a conversation.
  Future<ApiResponse<List<Message>>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.conversationMessages(conversationId),
      );

      return ApiResponse<List<Message>>.fromJson(
        response.data,
        (json) => (json as List)
            .map((e) => Message.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Rename a conversation.
  Future<ApiResponse<void>> renameConversation(
    String conversationId,
    String newTitle,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiPaths.conversation(conversationId),
        queryParameters: {'title': newTitle},
      );

      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Delete a conversation.
  Future<ApiResponse<void>> deleteConversation(String conversationId) async {
    try {
      final response = await _dioClient.dio.delete(
        ApiPaths.conversation(conversationId),
      );

      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get usage statistics.
  Future<ApiResponse<UsageSummary>> getUsage() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.usage);

      return ApiResponse<UsageSummary>.fromJson(
        response.data,
        (json) => UsageSummary.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
