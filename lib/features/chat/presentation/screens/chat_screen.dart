import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carento/core/constants/app_constants.dart';
import 'package:carento/features/chat/presentation/widgets/chat_message.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:carento/firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carento/features/chat/presentation/screens/chat_analytics_screen.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to use the chat')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // First, check if user has any existing chat sessions
      final chatSessions = await FirebaseFirestore.instance
          .collection('chat_sessions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('lastMessageTime', descending: true)
          .limit(1)
          .get();

      if (chatSessions.docs.isEmpty) {
        // Create a new chat session
        final newSession = await FirebaseFirestore.instance
            .collection('chat_sessions')
            .add({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'status': 'active',
          'title': 'New Chat',
        });

        // Add a welcome message
        await FirebaseFirestore.instance.collection('chats').add({
          'chatId': newSession.id,
          'userId': user.uid,
          'message': 'Hello! How can I help you with your car rental today?',
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _currentChatId = newSession.id;
        });
      } else {
        setState(() {
          _currentChatId = chatSessions.docs.first.id;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing chat: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _initializeChat,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> getGeminiResponse(String prompt) async {
    final model = GenerativeModel(model: 'gemini-pro', apiKey: 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E');
    final content = [Content.text(prompt)];
    final response = await model.generateContent(content);
    return response.text ?? "No response from Gemini.";
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChatId == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final message = _messageController.text.trim();
      _messageController.clear();

      // Add user message
      await FirebaseFirestore.instance.collection('chats').add({
        'chatId': _currentChatId,
        'userId': user.uid,
        'message': message,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update chat session
      await FirebaseFirestore.instance
          .collection('chat_sessions')
          .doc(_currentChatId)
          .update({
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      // Call Gemini directly for AI response
      try {
        final geminiResponse = await getGeminiResponse(message);
        await FirebaseFirestore.instance.collection('chats').add({
          'chatId': _currentChatId,
          'userId': user.uid,
          'message': geminiResponse,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        await FirebaseFirestore.instance.collection('chats').add({
          'chatId': _currentChatId,
          'userId': user.uid,
          'message': 'Error getting response from Gemini.',
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Support'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initializeChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _currentChatId == null
                ? const Center(child: Text('No chat session found.'))
                : StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .where('chatId', isEqualTo: _currentChatId)
                        .orderBy('timestamp', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: \\n${snapshot.error}'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final messages = snapshot.data?.docs ?? [];
                      if (messages.isEmpty) {
                        return const Center(child: Text('No messages yet.'));
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final raw = messages[index].data();
                          if (raw == null || raw is! Map<String, dynamic>) {
                            // Defensive: skip bad data
                            return const SizedBox.shrink();
                          }
                          final isUser = raw['isUser'] == true;
                          final messageText = raw['message']?.toString() ?? '[No message]';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                messageText,
                                style: TextStyle(
                                  color: isUser
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading || _currentChatId == null ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildCarImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Image.asset(
          'assets/images/car1.jpg', // fallback asset
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Image.asset(
        'assets/images/car1.jpg', // fallback asset
        fit: BoxFit.cover,
      );
    }
  }
}