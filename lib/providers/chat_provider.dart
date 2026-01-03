import 'package:flutter/foundation.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ConversationModel> _conversations = [];
  List<MessageModel> _messages = [];
  ConversationModel? _currentConversation;
  bool _isLoading = false;
  String? _error;

  List<ConversationModel> get conversations => _conversations;
  List<MessageModel> get messages => _messages;
  ConversationModel? get currentConversation => _currentConversation;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load conversations
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _conversations = await _chatService.getConversations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load conversations';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Open conversation
  Future<void> openConversation(String conversationId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Find conversation in list or load conversations first
      ConversationModel? conversation;
      try {
        conversation = _conversations.firstWhere((c) => c.id == conversationId);
      } catch (_) {
        // Not in list, reload conversations
        await loadConversations();
        try {
          conversation = _conversations.firstWhere((c) => c.id == conversationId);
        } catch (_) {
          // Still not found, might be a new conversation - set a placeholder
          conversation = null;
        }
      }

      _currentConversation = conversation;

      // Load messages
      _messages = await _chatService.getMessages(conversationId);

      // Subscribe to new messages
      _chatService.subscribeToMessages(conversationId, (newMessages) {
        _messages = newMessages.reversed.toList();
        notifyListeners();
      });

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to open conversation';
      _isLoading = false;
      notifyListeners();
      debugPrint('Error opening conversation: $e');
    }
  }

  // Start direct conversation
  Future<ConversationModel?> startDirectConversation(String otherUserId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final conversation = await _chatService.getOrCreateDirectConversation(otherUserId);
      _currentConversation = conversation;

      // Add to conversations list if not exists
      if (!_conversations.any((c) => c.id == conversation.id)) {
        _conversations.insert(0, conversation);
      }

      _isLoading = false;
      notifyListeners();

      return conversation;
    } catch (e) {
      _error = 'Failed to start conversation';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Create group conversation
  Future<ConversationModel?> createGroupConversation({
    required String name,
    required List<String> memberIds,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final conversation = await _chatService.createGroupConversation(
        name: name,
        memberIds: memberIds,
      );

      _conversations.insert(0, conversation);
      _currentConversation = conversation;

      _isLoading = false;
      notifyListeners();

      return conversation;
    } catch (e) {
      _error = 'Failed to create group';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Send message
  Future<bool> sendMessage(String content, {String type = 'text'}) async {
    try {
      if (_currentConversation == null) return false;

      final message = await _chatService.sendMessage(
        conversationId: _currentConversation!.id,
        content: content,
        type: type,
      );

      _messages.insert(0, message);
      notifyListeners();

      return true;
    } catch (e) {
      _error = 'Failed to send message';
      notifyListeners();
      return false;
    }
  }

  // Close conversation
  void closeConversation() {
    if (_currentConversation != null) {
      _chatService.unsubscribeFromMessages(_currentConversation!.id);
    }
    _currentConversation = null;
    _messages = [];
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatService.dispose();
    super.dispose();
  }
}
