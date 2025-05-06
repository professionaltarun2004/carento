import 'package:flutter/material.dart';

class ChatMessage extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.message,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : null,
            bottomLeft: !isUser ? const Radius.circular(0) : null,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
} 