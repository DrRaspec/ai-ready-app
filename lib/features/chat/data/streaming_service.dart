import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:ai_chat_bot/core/network/api_paths.dart';

class StreamingService {
  final Dio _dio;
  final String baseUrl;

  StreamingService({required Dio dio, required this.baseUrl}) : _dio = dio;

  Stream<String> streamChat(
    String message,
    String token, {
    String? conversationId,
    bool forceTextChat = true,
  }) async* {
    final url = '$baseUrl${ApiPaths.stream}';

    try {
      final response = await _dio.get(
        url,
        queryParameters: {
          'message': message,
          if (conversationId != null) 'conversationId': conversationId,
          'forceTextChat': forceTextChat,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;

      await for (final chunk in stream.transform(utf8.decoder)) {
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data == '[DONE]') return;
            yield data;
          }
        }
      }
    } catch (e) {
      yield 'Error: $e';
    }
  }
}
