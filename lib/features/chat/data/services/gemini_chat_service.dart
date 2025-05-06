import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  static const String _apiKey = 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E';
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiChatService() {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
  }

  Future<String> sendMessage(String message) async {
    try {
      final response = await _chat.sendMessage(
        Content.text(message),
      );
      return response.text ?? 'Sorry, I could not process your request.';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  Future<String> getCarRecommendation({
    required String budget,
    required String purpose,
    required String preferences,
  }) async {
    final prompt = '''
    Based on the following criteria, recommend a car:
    Budget: $budget
    Purpose: $purpose
    Preferences: $preferences
    
    Please provide a detailed recommendation including:
    1. Car model and make
    2. Key features
    3. Price range
    4. Why it's suitable for the given criteria
    ''';

    return sendMessage(prompt);
  }

  Future<String> getBookingHelp({
    required String query,
    required String context,
  }) async {
    final prompt = '''
    Help with car rental booking:
    Query: $query
    Context: $context
    
    Please provide clear, step-by-step guidance.
    ''';

    return sendMessage(prompt);
  }

  void resetChat() {
    _chat = _model.startChat();
  }
} 