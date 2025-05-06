import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatMessage {
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.role,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'role': role,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      content: map['content'] as String,
      role: map['role'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }
}

class GeminiChatService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  List<ChatMessage> _chatHistory = [];

  Future<ChatMessage> sendMessage(String message) async {
    try {
      // Add user message to history
      final userMessage = ChatMessage(
        content: message,
        role: 'user',
        timestamp: DateTime.now(),
      );
      _chatHistory.add(userMessage);

      // Call Cloud Function
      final result = await _functions.httpsCallable('chatWithGemini').call({
        'message': message,
        'chatHistory': _chatHistory.map((msg) => msg.toMap()).toList(),
      });

      // Create assistant message from response
      final assistantMessage = ChatMessage(
        content: result.data['response'] as String,
        role: 'assistant',
        timestamp: DateTime.parse(result.data['timestamp'] as String),
      );
      _chatHistory.add(assistantMessage);

      return assistantMessage;
    } on FirebaseFunctionsException catch (e) {
      String errorMessage = 'Failed to send message';
      switch (e.code) {
        case 'unauthenticated':
          errorMessage = 'You must be signed in to use chat';
          break;
        case 'invalid-argument':
          errorMessage = 'Invalid message format';
          break;
        case 'resource-exhausted':
          errorMessage = 'Service is temporarily unavailable. Please try again later';
          break;
        case 'internal':
          errorMessage = 'An internal error occurred. Please try again later';
          break;
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }

  List<ChatMessage> get chatHistory => _chatHistory;

  void clearHistory() {
    _chatHistory.clear();
  }
}

final geminiChatServiceProvider = Provider<GeminiChatService>((ref) {
  return GeminiChatService();
}); 