import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ChatApiService {
  static Map<String, String> _headers(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// List conversations for authenticated user
  static Future<List<ConversationModel>> getConversations(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
    final response = await http
        .get(url, headers: _headers(token))
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Tiempo de espera agotado al obtener las conversaciones.');
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((item) => ConversationModel.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Sesión expirada. Por favor vuelve a iniciar sesión.');
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al cargar conversaciones (${response.statusCode})');
    }
  }

  /// Create a new conversation
  static Future<ConversationModel> createConversation(String token, {String? title}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations');
    final response = await http
        .post(
          url,
          headers: _headers(token),
          body: jsonEncode({
            if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
          }),
        )
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Tiempo de espera agotado al iniciar la conversación.');
    });

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ConversationModel.fromJson(data['data']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al crear conversación (${response.statusCode})');
    }
  }

  /// Get messages of a conversation
  static Future<List<ChatMessageModel>> getMessages(String token, int conversationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations/$conversationId/messages');
    final response = await http
        .get(url, headers: _headers(token))
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw Exception('Tiempo de espera agotado al cargar el historial.');
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['data'] ?? [];
      return list.map((item) => ChatMessageModel.fromJson(item)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Error al obtener mensajes (${response.statusCode})');
    }
  }

  /// Send message to Gemini through Laravel backend
  static Future<Map<String, dynamic>> sendMessage(
    String token,
    int conversationId,
    String message,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations/$conversationId/messages');
    final response = await http
        .post(
          url,
          headers: _headers(token),
          body: jsonEncode({'message': message}),
        )
        .timeout(const Duration(seconds: 35), onTimeout: () {
      throw Exception('Gemini tardó demasiado en responder. Por favor intenta de nuevo.');
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 'success') {
      return {
        'respuesta': data['respuesta'] ?? '',
        'conversation_id': data['conversation_id'] ?? conversationId,
        'user_message': data['data']?['user_message'] != null
            ? ChatMessageModel.fromJson(data['data']['user_message'])
            : null,
        'bot_message': data['data']?['bot_message'] != null
            ? ChatMessageModel.fromJson(data['data']['bot_message'])
            : null,
      };
    } else {
      final errorMsg = data['message'] ?? 'Error al procesar mensaje en el servidor';
      throw Exception(errorMsg);
    }
  }

  /// Delete a conversation
  static Future<bool> deleteConversation(String token, int conversationId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/chat/conversations/$conversationId');
    final response = await http.delete(url, headers: _headers(token));
    return response.statusCode == 200;
  }
}
