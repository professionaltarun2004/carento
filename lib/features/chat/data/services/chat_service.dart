import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carento/features/chat/domain/models/chat_message.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get chat messages between two users
  Stream<List<ChatMessage>> getChatMessages(String otherUserId) {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return Stream.value([]);
      return _firestore
          .collection('chats')
          .where('participants', arrayContainsAny: [currentUserId, otherUserId])
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              return snapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .where((message) =>
                      (message.senderId == currentUserId &&
                          message.receiverId == otherUserId) ||
                      (message.senderId == otherUserId &&
                          message.receiverId == currentUserId))
                  .toList()
                  .cast<ChatMessage>();
            } catch (e) {
              print('Error processing chat messages: $e');
              return <ChatMessage>[];
            }
          })
          .handleError((error) {
            print('Error in chat stream: $error');
            return [];
          });
    } catch (e) {
      print('Error setting up chat stream: $e');
      return Stream.value([]);
    }
  }

  // Send a message
  Future<String?> sendMessage({
    required String receiverId,
    required String message,
    String? imageUrl,
  }) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return 'User not authenticated';

      if (message.trim().isEmpty) return 'Message cannot be empty';

      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );

      await _firestore
          .collection('chats')
          .doc(chatMessage.id)
          .set(chatMessage.toMap());
      return null;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return 'You do not have permission to send messages';
      } else if (e.code == 'unavailable') {
        return 'Service is temporarily unavailable. Please try again later';
      }
      return 'Failed to send message: ${e.message}';
    } catch (e) {
      return 'Failed to send message: ${e.toString()}';
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return;

      final batch = _firestore.batch();
      final messages = await _firestore
          .collection('chats')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      if (messages.docs.isEmpty) return;

      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Get unread message count
  Stream<int> getUnreadMessageCount(String senderId) {
    try {
      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) return Stream.value(0);

      return _firestore
          .collection('chats')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isRead', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length)
          .handleError((error) {
        print('Error in unread message count stream: $error');
        return 0;
      });
    } catch (e) {
      print('Error setting up unread message count stream: $e');
      return Stream.value(0);
    }
  }
}
