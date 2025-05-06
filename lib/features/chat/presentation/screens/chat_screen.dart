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

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

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
      _messageController.clear();
    });

    try {
      // Add user message to Firestore
      await FirebaseFirestore.instance.collection(AppConstants.chatCollection).add({
        'userId': user.uid,
        'message': message,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Call Cloud Function to get Gemini response
      final response = await _getGeminiResponse(message);

      // Add bot response to Firestore
      await FirebaseFirestore.instance.collection(AppConstants.chatCollection).add({
        'userId': user.uid,
        'message': response,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred';
        if (e.code == 'permission-denied') {
          errorMessage = 'You do not have permission to send messages';
        } else if (e.code == 'unavailable') {
          errorMessage = 'Service is temporarily unavailable';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _getGeminiResponse(String message) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('geminiChat');
      final result = await callable.call({'message': message});
      return result.data['reply'] ?? 'No response from Gemini.';
    } catch (e) {
      if (e is FirebaseFunctionsException) {
        switch (e.code) {
          case 'not-found':
            return 'Chat service is not available. Please try again later.';
          case 'permission-denied':
            return 'You do not have permission to use the chat service.';
          case 'unavailable':
            return 'Chat service is temporarily unavailable. Please try again later.';
          default:
            return 'An error occurred: ${e.message}';
        }
      }
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to use the chat'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.chatCollection)
                  .where('userId', isEqualTo: user.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final errorMsg = snapshot.error.toString();
                  if (errorMsg.contains('failed-precondition') && errorMsg.contains('index')) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'A Firestore index is required for this chat feature.',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please ask the admin to create the required index in the Firebase Console.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (errorMsg.contains('permission-denied')) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline, color: Colors.orange, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'You do not have permission to access chat.',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please sign in or contact support.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Center(child: Text('Error: $errorMsg'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ask me anything about cars, bookings, or support',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    return ChatMessage(
                      message: message['message'] as String,
                      isUser: message['isUser'] as bool,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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