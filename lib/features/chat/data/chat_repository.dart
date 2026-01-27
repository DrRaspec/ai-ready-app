import 'dart:convert';
import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/features/chat/data/models/image_generation_request.dart';
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

  /// Send a vision chat message (uses llama-3.2-11b-vision-preview).
  Future<ApiResponse<ChatResponse>> sendVisionMessage(
    ChatRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.visionChat,
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

  /// Send a vision message to an existing conversation.
  Future<ApiResponse<ChatResponse>> sendVisionMessageToConversation(
    String conversationId,
    ChatRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.visionChatWithConversation(conversationId),
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

  /// Generate an image from a prompt.
  Future<ApiResponse<ChatResponse>> generateImage(
    ImageGenerationRequest request,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.generateImage,
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

      var responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          // responseData remains a String here if decode fails
        }
      }

      final Map<String, dynamic> jsonMap;
      if (responseData is Map<String, dynamic>) {
        jsonMap = responseData;
      } else if (responseData is Map) {
        jsonMap = Map<String, dynamic>.from(responseData);
      } else {
        // If completely failed to parse or format is wrong, return empty structure or throw
        // But to avoid crash, let's try to infer if it might be just the list
        jsonMap = {};
      }

      return ApiResponse<List<Conversation>>.fromJson(jsonMap, (json) {
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

  /// Edit a message.
  Future<ApiResponse<ChatResponse>> editMessage(
    String conversationId,
    String messageId,
    String newContent,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        ApiPaths.editMessage(conversationId, messageId),
        data: {'message': newContent},
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
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
        data: {'title': newTitle},
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
