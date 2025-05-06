import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiChatService {
  static const String _apiKey = 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E';
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiChatService() {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_API_KEY') {
      throw Exception('Gemini API key is not configured. Please set a valid API key.');
    }
    
    try {
      _model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
      _chat = _model.startChat();
    } catch (e) {
      throw Exception('Failed to initialize Gemini chat: ${e.toString()}');
    }
  }

  Future<String> sendMessage(String message) async {
    if (message.trim().isEmpty) {
      return 'Please enter a message';
    }
    
    try {
      final response = await _chat.sendMessage(
        Content.text(message),
      );
      return response.text ?? 'Sorry, I could not process your request.';
    } on Exception catch (e) {
      if (e.toString().contains('API key')) {
        return 'Error: Invalid API key configuration. Please check your configuration.';
      } else if (e.toString().contains('network')) {
        return 'Error: Network connection failed. Please check your internet connection.';
      } else if (e.toString().contains('quota')) {
        return 'Error: API quota exceeded. Please try again later.';
      } else if (e.toString().contains('invalid')) {
        return 'Error: Invalid request. Please try again.';
      } else if (e.toString().contains('timeout')) {
        return 'Error: Request timed out. Please try again.';
      }
      return 'Error: ${e.toString()}';
    }
  }

  Future<String> getCarRecommendation({
    required String budget,
    required String purpose,
    required String preferences,
  }) async {
    if (budget.trim().isEmpty) {
      return 'Please specify your budget';
    }
    if (purpose.trim().isEmpty) {
      return 'Please specify the purpose of the car';
    }
    
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
    if (query.trim().isEmpty) {
      return 'Please specify your query';
    }
    
    final prompt = '''
    Help with car rental booking:
    Query: $query
    Context: $context
    
    Please provide clear, step-by-step guidance.
    ''';

    return sendMessage(prompt);
  }

  void resetChat() {
    try {
      _chat = _model.startChat();
    } catch (e) {
      throw Exception('Failed to reset chat: ${e.toString()}');
    }
  }
} 