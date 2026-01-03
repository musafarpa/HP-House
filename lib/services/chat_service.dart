import 'dart:async';
import '../config/supabase_config.dart';
import '../models/message_model.dart';
import 'database_service.dart';

class ChatService {
  final DatabaseService _db = DatabaseService();
  final Map<String, StreamSubscription> _subscriptions = {};

  // Send message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
  }) async {
    final senderId = SupabaseConfig.currentUserId;
    if (senderId == null) throw Exception('User not authenticated');

    return await _db.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
    );
  }

  // Get messages
  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50}) async {
    return await _db.getMessages(conversationId, limit: limit);
  }

  // Subscribe to messages
  void subscribeToMessages(
    String conversationId,
    void Function(List<MessageModel> messages) onMessages,
  ) {
    // Cancel existing subscription
    _subscriptions[conversationId]?.cancel();

    // Create new subscription
    final subscription = _db.watchMessages(conversationId).listen((data) {
      final messages = data.map((e) {
        final msg = Map<String, dynamic>.from(e);
        return MessageModel.fromJson(msg);
      }).toList();

      onMessages(messages);
    });

    _subscriptions[conversationId] = subscription;
  }

  // Unsubscribe from messages
  void unsubscribeFromMessages(String conversationId) {
    _subscriptions[conversationId]?.cancel();
    _subscriptions.remove(conversationId);
  }

  // Get or create direct conversation
  Future<ConversationModel> getOrCreateDirectConversation(String otherUserId) async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) throw Exception('User not authenticated');

    // Try to find existing conversation
    var conversation = await _db.getDirectConversation(currentUserId, otherUserId);

    if (conversation == null) {
      // Create new conversation
      conversation = await _db.createConversation(
        type: 'direct',
        memberIds: [currentUserId, otherUserId],
      );
    }

    // Get the other user's details to populate name/avatar
    final otherUser = await _db.getUser(otherUserId);
    if (otherUser != null) {
      conversation = ConversationModel(
        id: conversation.id,
        type: conversation.type,
        roomId: conversation.roomId,
        name: otherUser.displayNameOrUsername,
        avatarUrl: otherUser.avatarUrl,
        memberIds: conversation.memberIds,
        lastMessage: conversation.lastMessage,
        unreadCount: conversation.unreadCount,
        createdAt: conversation.createdAt,
      );
    }

    return conversation;
  }

  // Get conversations
  Future<List<ConversationModel>> getConversations() async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) throw Exception('User not authenticated');

    return await _db.getConversations(currentUserId);
  }

  // Create group conversation
  Future<ConversationModel> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    final currentUserId = SupabaseConfig.currentUserId;
    if (currentUserId == null) throw Exception('User not authenticated');

    return await _db.createConversation(
      type: 'group',
      name: name,
      memberIds: [currentUserId, ...memberIds],
    );
  }

  // Dispose all subscriptions
  void dispose() {
    for (final subscription in _subscriptions.values) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
