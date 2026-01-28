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

import 'package:ai_chat_bot/features/chat/data/models/search_result.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(DioClient dioClient) : _dioClient = dioClient;

  /// Send a smart message (unified endpoint).
  /// Uses /ai/smart for first message, /ai/smart/{conversationId} for subsequent messages.
  Future<ApiResponse<ChatResponse>> sendSmartMessage(
    ChatRequest request,
  ) async {
    try {
      // Use conversation-specific endpoint if we have a conversationId
      final path = request.conversationId != null
          ? ApiPaths.smartWithConversation(request.conversationId!)
          : ApiPaths.smart;

      final response = await _dioClient.dio.post(path, data: request.toJson());

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Share a conversation.
  Future<ApiResponse<String>> shareConversation(String conversationId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.shareConversation(conversationId),
      );

      // User snippet says: jsonDecode(response.body)['data']['shareUrl']
      // ApiResponse handles wrapping. 'data' usually contains the payload.
      // If server returns { success: true, data: { shareUrl: "..." } }
      // We expect generic parser to extract 'data'.
      // So passed json is { shareUrl: "..." }
      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic> && json['shareUrl'] != null) {
          return json['shareUrl'] as String;
        }
        return '';
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get user preferences.
  Future<ApiResponse<Map<String, dynamic>>> getPreferences() async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.preferences);
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Update user preferences.
  Future<ApiResponse<Map<String, dynamic>>> updatePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final response = await _dioClient.dio.put(
        ApiPaths.preferences,
        data: preferences,
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Send a new chat message (creates new conversation).
  @Deprecated(
    'Use sendSmartMessage instead - unified endpoint with conversation context',
  )
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
  @Deprecated(
    'Use sendSmartMessage instead - unified endpoint with conversation context',
  )
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
  @Deprecated(
    'Use sendSmartMessage with imageBase64 - backend auto-detects vision mode',
  )
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
  @Deprecated(
    'Use sendSmartMessage with imageBase64 - backend auto-detects vision mode',
  )
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

  /// Edit an image.
  Future<ApiResponse<ChatResponse>> editImage({
    required String prompt,
    required String imagePath,
  }) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'prompt': prompt,
        'file': await MultipartFile.fromFile(imagePath, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        ApiPaths.editImage,
        data: formData,
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Enhance a prompt.
  Future<ApiResponse<String>> enhancePrompt(String prompt) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.enhancePrompt,
        data: {'prompt': prompt},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic> && json['enhancedPrompt'] != null) {
          return json['enhancedPrompt'] as String;
        }
        // Fallback if the user example response structure matches data['data']['enhancedPrompt']
        // but generic parser expects data to be the object.
        // User example: data['data']['enhancedPrompt']
        // ApiResponse usually extracts 'data'. So 'json' here is 'data'.
        // If 'data' contains 'enhancedPrompt', we are good.
        return json.toString();
      });
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
        ApiPaths.messages(conversationId),
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

  /// Regenerate response.
  Future<ApiResponse<ChatResponse>> regenerate(String conversationId) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.regenerate(conversationId),
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Get conversation summary.
  Future<ApiResponse<String>> getSummary(String conversationId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.summary(conversationId),
      );

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic> && json['summary'] != null) {
          return json['summary'] as String;
        }
        return '';
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Rate message feedback.
  Future<ApiResponse<void>> rateFeedback(
    String messageId,
    bool isPositive,
  ) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.feedback(messageId),
        queryParameters: {'isPositive': isPositive},
      );

      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Perform web search.
  Future<ApiResponse<List<SearchResult>>> webSearch(String query) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.search,
        queryParameters: {'query': query},
      );

      return ApiResponse<List<SearchResult>>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic> && json['results'] != null) {
          return (json['results'] as List)
              .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return [];
      });
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
