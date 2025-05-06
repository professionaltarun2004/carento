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
        return snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc))
            .where((message) =>
                (message.senderId == currentUserId && message.receiverId == otherUserId) ||
                (message.senderId == otherUserId && message.receiverId == currentUserId))
            .toList();
      });
    } catch (e) {
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
      final chatMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUserId,
        receiverId: receiverId,
        message: message,
        timestamp: DateTime.now(),
        imageUrl: imageUrl,
      );
      await _firestore.collection('chats').doc(chatMessage.id).set(chatMessage.toMap());
      return null;
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
      for (var doc in messages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      // Handle error
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
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      return Stream.value(0);
    }
  }
} 