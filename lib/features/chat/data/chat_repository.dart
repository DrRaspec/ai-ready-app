import 'dart:convert';

import 'package:ai_chat_bot/core/errors/api_exception.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';
import 'package:ai_chat_bot/core/network/dio_client.dart';
import 'package:ai_chat_bot/core/network/models/api_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/chat_response.dart';
import 'package:ai_chat_bot/features/chat/data/models/conversation.dart';
import 'package:ai_chat_bot/features/chat/data/models/image_generation_request.dart';
import 'package:ai_chat_bot/features/chat/data/models/message.dart';
import 'package:ai_chat_bot/features/chat/data/models/search_result.dart';
import 'package:ai_chat_bot/features/chat/data/models/usage_summary.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final DioClient _dioClient;

  ChatRepository(DioClient dioClient) : _dioClient = dioClient;

  Future<ApiResponse<ChatResponse>> sendSmartMessage(
    ChatRequest request,
  ) async {
    try {
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

  Stream<String> streamSmartMessage(ChatRequest request) async* {
    try {
      final path = request.conversationId != null
          ? ApiPaths.streamChatWithConversation(request.conversationId!)
          : ApiPaths.streamChat;

      final response = await _dioClient.dio.post(
        path,
        data: request.toJson(),
        options: Options(
          responseType: ResponseType.stream,
          headers: {'Accept': 'text/event-stream'},
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;

      yield* stream
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .map((line) {
            if (!line.startsWith('data:')) return '';

            var data = line.substring(5);
            if (data.contains('[CONV_ID:')) {
              data = data.replaceAll(RegExp(r'\[CONV_ID:[^\]]+\]'), '');
            }
            if (data.trim() == '[DONE]') return '';
            return data;
          })
          .where((chunk) => chunk.isNotEmpty);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<String>> shareConversation(
    String conversationId, {
    int? expiresInDays,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.shareConversation(conversationId),
        queryParameters: {
          if (expiresInDays != null) 'expiresInDays': expiresInDays,
        },
      );

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return (json['shareUrl'] ?? '').toString();
        }
        return '';
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> unshareConversation(String conversationId) async {
    try {
      final response = await _dioClient.dio.delete(
        ApiPaths.shareConversation(conversationId),
      );
      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getSharedConversation(
    String token,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.sharedConversation(token),
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<ApiResponse<String>> enhancePrompt(String prompt) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.enhancePrompt,
        queryParameters: {'prompt': prompt},
      );

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return (json['enhancedPrompt'] ?? '').toString();
        }
        return json.toString();
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<List<Conversation>>> getConversations({
    int page = 0,
    int size = 20,
    String? folderId,
    String? sort,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'size': size};
      if (folderId != null) queryParams['folderId'] = folderId;
      if (sort != null) queryParams['sort'] = sort;

      final response = await _dioClient.dio.get(
        ApiPaths.conversations,
        queryParameters: queryParams,
      );

      final responseData = response.data is String
          ? (jsonDecode(response.data as String) as Map<String, dynamic>)
          : Map<String, dynamic>.from(response.data as Map);

      return ApiResponse<List<Conversation>>.fromJson(responseData, (json) {
        if (json is Map && json['content'] is List) {
          return (json['content'] as List)
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList();
        }
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

  Future<ApiResponse<List<Conversation>>> searchConversations(
    String query, {
    int page = 0,
    int size = 20,
    String? sort,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.conversationsSearch,
        queryParameters: {
          'q': query,
          'page': page,
          'size': size,
          if (sort != null) 'sort': sort,
        },
      );

      return ApiResponse<List<Conversation>>.fromJson(response.data, (json) {
        if (json is Map && json['content'] is List) {
          return (json['content'] as List)
              .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
              .toList();
        }
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

  Future<ApiResponse<ChatResponse>> editMessage(
    String conversationId,
    String messageId,
    String newContent, {
    String? systemPrompt,
  }) async {
    try {
      final response = await _dioClient.dio.put(
        ApiPaths.editMessage(conversationId, messageId),
        data: {
          'content': newContent,
          if (systemPrompt != null) 'systemPrompt': systemPrompt,
        },
      );

      return ApiResponse<ChatResponse>.fromJson(
        response.data,
        (json) => ChatResponse.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<ApiResponse<void>> moveConversationToFolder(
    String conversationId,
    String? folderId,
  ) async {
    try {
      final response = await _dioClient.dio.patch(
        ApiPaths.conversationFolder(conversationId),
        data: {'folderId': folderId},
      );

      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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

  Future<ApiResponse<String>> getSummary(String conversationId) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.summary(conversationId),
      );

      return ApiResponse<String>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return (json['summary'] ?? '').toString();
        }
        return '';
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getSummaryDetails(
    String conversationId,
  ) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.summary(conversationId),
      );
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<void>> rateFeedback(
    String messageId,
    bool isPositive, {
    String? feedbackText,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.feedback(messageId),
        queryParameters: {
          'isPositive': isPositive,
          if (feedbackText != null && feedbackText.isNotEmpty)
            'feedbackText': feedbackText,
        },
      );

      return ApiResponse<void>.fromJson(response.data, (_) {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> getFeedbackStats(
    String messageId,
  ) async {
    try {
      final response = await _dioClient.dio.get(ApiPaths.feedback(messageId));
      return ApiResponse<Map<String, dynamic>>.fromJson(
        response.data,
        (json) => json as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<List<SearchResult>>> webSearch(
    String query, {
    int? limit,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.search,
        queryParameters: {'query': query, if (limit != null) 'limit': limit},
      );

      return ApiResponse<List<SearchResult>>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic> && json['results'] is List) {
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

  Future<ApiResponse<bool>> needsWebSearch(String query) async {
    try {
      final response = await _dioClient.dio.get(
        ApiPaths.searchNeedsSearch,
        queryParameters: {'query': query},
      );

      return ApiResponse<bool>.fromJson(response.data, (json) {
        if (json is Map<String, dynamic>) {
          return json['needsWebSearch'] as bool? ?? false;
        }
        return false;
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

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
