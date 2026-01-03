import '../config/supabase_config.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  final _db = SupabaseConfig.client;

  // ==================== USERS ====================

  Future<UserModel?> getUser(String userId) async {
    final response = await _db
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  Future<List<UserModel>> searchUsers(String query, {String? excludeUserId}) async {
    var queryBuilder = _db.from('profiles').select();

    // If query is not empty, filter by username or display_name
    if (query.isNotEmpty) {
      queryBuilder = queryBuilder.or('username.ilike.%$query%,display_name.ilike.%$query%');
    }

    if (excludeUserId != null) {
      queryBuilder = queryBuilder.neq('id', excludeUserId);
    }

    final response = await queryBuilder.limit(50);

    return (response as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // Get all users (for member list)
  Future<List<UserModel>> getAllUsers({String? excludeUserId}) async {
    var queryBuilder = _db.from('profiles').select();

    if (excludeUserId != null) {
      queryBuilder = queryBuilder.neq('id', excludeUserId);
    }

    final response = await queryBuilder.order('created_at', ascending: false).limit(100);

    return (response as List)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ==================== FOLLOWERS ====================

  Future<void> followUser(String followerId, String followingId) async {
    await _db.from('followers').insert({
      'follower_id': followerId,
      'following_id': followingId,
    });
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    await _db
        .from('followers')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final response = await _db
        .from('followers')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();

    return response != null;
  }

  Future<List<UserModel>> getFollowers(String userId) async {
    final response = await _db
        .from('followers')
        .select('follower:profiles!follower_id(*)')
        .eq('following_id', userId);

    return (response as List)
        .map((e) => UserModel.fromJson(e['follower'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> getFollowing(String userId) async {
    final response = await _db
        .from('followers')
        .select('following:profiles!following_id(*)')
        .eq('follower_id', userId);

    return (response as List)
        .map((e) => UserModel.fromJson(e['following'] as Map<String, dynamic>))
        .toList();
  }

  // ==================== ROOMS ====================

  Future<RoomModel> createRoom({
    required String title,
    String? description,
    required String hostId,
    RoomType type = RoomType.audio,
    int maxParticipants = 12,
  }) async {
    final response = await _db.from('rooms').insert({
      'title': title,
      'description': description,
      'host_id': hostId,
      'type': type == RoomType.video ? 'video' : 'audio',
      'is_live': true,
      'max_participants': maxParticipants,
    }).select('''
      *,
      host:profiles!host_id(display_name, avatar_url)
    ''').single();

    // Add host as participant
    await joinRoom(response['id'], hostId, role: 'host');

    // Build room with host info
    final room = Map<String, dynamic>.from(response);
    room['host_name'] = response['host']?['display_name'];
    room['host_avatar_url'] = response['host']?['avatar_url'];
    room['participants_count'] = 1; // Host is the first participant

    return RoomModel.fromJson(room);
  }

  Future<List<RoomModel>> getLiveRooms() async {
    final response = await _db
        .from('rooms')
        .select('''
          *,
          host:profiles!host_id(display_name, avatar_url),
          participants_count:room_participants(count)
        ''')
        .eq('is_live', true)
        .order('created_at', ascending: false);

    return (response as List).map((e) {
      final room = Map<String, dynamic>.from(e);
      room['host_name'] = e['host']?['display_name'];
      room['host_avatar_url'] = e['host']?['avatar_url'];
      room['participants_count'] = e['participants_count']?[0]?['count'] ?? 0;
      return RoomModel.fromJson(room);
    }).toList();
  }

  // Get ALL rooms (including offline rooms)
  Future<List<RoomModel>> getAllRooms() async {
    final response = await _db
        .from('rooms')
        .select('''
          *,
          host:profiles!host_id(display_name, avatar_url),
          participants_count:room_participants(count)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((e) {
      final room = Map<String, dynamic>.from(e);
      room['host_name'] = e['host']?['display_name'];
      room['host_avatar_url'] = e['host']?['avatar_url'];
      room['participants_count'] = e['participants_count']?[0]?['count'] ?? 0;
      return RoomModel.fromJson(room);
    }).toList();
  }

  // Toggle room online/offline status
  Future<void> toggleRoomStatus(String roomId, bool isLive) async {
    await _db.from('rooms').update({'is_live': isLive}).eq('id', roomId);
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final response = await _db
        .from('rooms')
        .select('''
          *,
          host:profiles!host_id(display_name, avatar_url)
        ''')
        .eq('id', roomId)
        .single();

    final room = Map<String, dynamic>.from(response);
    room['host_name'] = response['host']?['display_name'];
    room['host_avatar_url'] = response['host']?['avatar_url'];

    return RoomModel.fromJson(room);
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> updates) async {
    await _db.from('rooms').update(updates).eq('id', roomId);
  }

  Future<void> endRoom(String roomId) async {
    await _db.from('rooms').update({'is_live': false}).eq('id', roomId);
    await _db.from('room_participants').delete().eq('room_id', roomId);
  }

  Future<void> deleteRoom(String roomId) async {
    // First delete all participants
    await _db.from('room_participants').delete().eq('room_id', roomId);
    // Then delete the room
    await _db.from('rooms').delete().eq('id', roomId);
  }

  // ==================== ROOM PARTICIPANTS ====================

  Future<void> joinRoom(String roomId, String odiumId, {String role = 'listener'}) async {
    try {
      print('DatabaseService: joinRoom called - roomId: $roomId, odiumId: $odiumId, role: $role');

      // First check if already in room
      final existing = await _db
          .from('room_participants')
          .select('id')
          .eq('room_id', roomId)
          .eq('user_id', odiumId)
          .maybeSingle();

      print('DatabaseService: Existing participant check: $existing');

      if (existing != null) {
        // Already in room, just update role if needed
        print('DatabaseService: Updating existing participant');
        await _db
            .from('room_participants')
            .update({'role': role, 'is_muted': true})
            .eq('room_id', roomId)
            .eq('user_id', odiumId);
      } else {
        // Not in room, insert new participant
        print('DatabaseService: Inserting new participant');
        await _db.from('room_participants').insert({
          'room_id': roomId,
          'user_id': odiumId,
          'role': role,
          'is_muted': true,
        });
      }
      print('DatabaseService: joinRoom completed successfully');
    } catch (e) {
      print('DatabaseService: Error in joinRoom: $e');
      rethrow;
    }
  }

  Future<void> leaveRoom(String roomId, String odiumId) async {
    await _db
        .from('room_participants')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', odiumId);
  }

  // Remove user from ALL rooms (called on logout)
  Future<void> leaveAllRooms(String userId) async {
    try {
      await _db
          .from('room_participants')
          .delete()
          .eq('user_id', userId);
      print('DatabaseService: User $userId removed from all rooms');
    } catch (e) {
      print('DatabaseService: Error removing user from all rooms: $e');
    }
  }

  Future<void> updateParticipant(
    String roomId,
    String odiumId,
    Map<String, dynamic> updates,
  ) async {
    await _db
        .from('room_participants')
        .update(updates)
        .eq('room_id', roomId)
        .eq('user_id', odiumId);
  }

  Stream<List<Map<String, dynamic>>> watchRoomParticipants(String roomId) {
    return _db
        .from('room_participants')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId);
  }

  // Get participants with user details (non-stream version)
  Future<List<Map<String, dynamic>>> getRoomParticipants(String roomId) async {
    try {
      print('DatabaseService: Getting participants for room $roomId');

      // Try using a join query first (works on web)
      try {
        final joinResponse = await _db
            .from('room_participants')
            .select('*, profiles:user_id(id, username, display_name, avatar_url)')
            .eq('room_id', roomId);

        print('DatabaseService: Join response: $joinResponse');

        if ((joinResponse as List).isNotEmpty) {
          final List<Map<String, dynamic>> result = [];
          for (var p in joinResponse) {
            final participant = Map<String, dynamic>.from(p);
            final profile = p['profiles'];
            if (profile != null) {
              participant['user_name'] = profile['display_name'] ?? profile['username'] ?? 'Unknown';
              participant['avatar_url'] = profile['avatar_url'];
            } else {
              participant['user_name'] = 'Unknown';
            }
            // Remove the nested profiles object
            participant.remove('profiles');
            result.add(participant);
          }
          print('DatabaseService: Join query result: $result');
          return result;
        }
      } catch (joinError) {
        print('DatabaseService: Join query failed, falling back to separate queries: $joinError');
      }

      // Fallback: Get participants first, then fetch profiles separately
      final participantsResponse = await _db
          .from('room_participants')
          .select('*')
          .eq('room_id', roomId);

      print('DatabaseService: Raw participants: $participantsResponse');

      if ((participantsResponse as List).isEmpty) {
        print('DatabaseService: No participants found');
        return [];
      }

      final List<Map<String, dynamic>> result = [];

      for (var p in participantsResponse) {
        final participant = Map<String, dynamic>.from(p);
        final odiumId = p['user_id'] as String?;

        print('DatabaseService: Processing participant with user_id: $odiumId');

        if (odiumId != null) {
          // Fetch user profile separately
          try {
            final userResponse = await _db
                .from('profiles')
                .select('id, username, display_name, avatar_url')
                .eq('id', odiumId)
                .maybeSingle();

            print('DatabaseService: User profile response: $userResponse');

            if (userResponse != null) {
              participant['user_name'] = userResponse['display_name'] ?? userResponse['username'] ?? 'Unknown';
              participant['avatar_url'] = userResponse['avatar_url'];
            } else {
              participant['user_name'] = 'Unknown';
            }
          } catch (e) {
            print('DatabaseService: Error fetching user profile: $e');
            participant['user_name'] = 'Unknown';
          }
        } else {
          participant['user_name'] = 'Unknown';
        }

        result.add(participant);
      }

      print('DatabaseService: Final result: $result');
      return result;
    } catch (e) {
      print('DatabaseService: Error getting participants: $e');
      rethrow;
    }
  }

  // ==================== CONVERSATIONS ====================

  Future<ConversationModel> createConversation({
    required String type,
    String? roomId,
    String? name,
    required List<String> memberIds,
  }) async {
    final currentUserId = SupabaseConfig.currentUserId;

    final response = await _db.from('conversations').insert({
      'type': type,
      'room_id': roomId,
      'name': name,
      'created_by': currentUserId,
    }).select().single();

    // Add members
    for (final memberId in memberIds) {
      await _db.from('conversation_members').insert({
        'conversation_id': response['id'],
        'user_id': memberId,
        'is_admin': memberId == currentUserId,
      });
    }

    return ConversationModel.fromJson(response);
  }

  Future<List<ConversationModel>> getConversations(String userId) async {
    final response = await _db
        .from('conversation_members')
        .select('conversation:conversations(*)')
        .eq('user_id', userId);

    final conversations = <ConversationModel>[];

    for (final item in response as List) {
      final conv = Map<String, dynamic>.from(item['conversation'] as Map<String, dynamic>);

      // For direct conversations, get the other user's info
      if (conv['type'] == 'direct') {
        final members = await _db
            .from('conversation_members')
            .select('user:profiles!user_id(id, username, display_name, avatar_url)')
            .eq('conversation_id', conv['id'])
            .neq('user_id', userId);

        if ((members as List).isNotEmpty) {
          final otherUser = members[0]['user'];
          conv['name'] = otherUser['display_name'] ?? otherUser['username'];
          conv['avatar_url'] = otherUser['avatar_url'];
        }
      }

      // Get last message
      final lastMsgResponse = await _db
          .from('messages')
          .select('*, sender:profiles!sender_id(display_name, avatar_url)')
          .eq('conversation_id', conv['id'])
          .order('created_at', ascending: false)
          .limit(1);

      if ((lastMsgResponse as List).isNotEmpty) {
        final lastMsg = Map<String, dynamic>.from(lastMsgResponse[0]);
        lastMsg['sender_name'] = lastMsgResponse[0]['sender']?['display_name'];
        lastMsg['sender_avatar_url'] = lastMsgResponse[0]['sender']?['avatar_url'];
        conv['last_message'] = lastMsg;
      }

      conversations.add(ConversationModel.fromJson(conv));
    }

    // Sort by last message time (most recent first)
    conversations.sort((a, b) {
      final aTime = a.lastMessage?.createdAt ?? a.createdAt;
      final bTime = b.lastMessage?.createdAt ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    return conversations;
  }

  Future<ConversationModel?> getDirectConversation(String user1Id, String user2Id) async {
    // Find existing direct conversation between two users
    // Get all conversation_ids where user1 is a member
    final user1Convs = await _db
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', user1Id);

    if ((user1Convs as List).isEmpty) {
      return null;
    }

    final conversationIds = (user1Convs)
        .map((e) => e['conversation_id'] as String)
        .toList();

    // Find direct conversations that also have user2
    for (final convId in conversationIds) {
      // Check if this is a direct conversation
      final conv = await _db
          .from('conversations')
          .select()
          .eq('id', convId)
          .eq('type', 'direct')
          .maybeSingle();

      if (conv != null) {
        // Check if user2 is also a member
        final user2Member = await _db
            .from('conversation_members')
            .select('id')
            .eq('conversation_id', convId)
            .eq('user_id', user2Id)
            .maybeSingle();

        if (user2Member != null) {
          return ConversationModel.fromJson(conv);
        }
      }
    }

    return null;
  }

  // ==================== MESSAGES ====================

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    String type = 'text',
  }) async {
    final response = await _db.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': type,
    }).select().single();

    return MessageModel.fromJson(response);
  }

  Future<List<MessageModel>> getMessages(String conversationId, {int limit = 50}) async {
    final response = await _db
        .from('messages')
        .select('''
          *,
          sender:profiles!sender_id(display_name, avatar_url)
        ''')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((e) {
      final msg = Map<String, dynamic>.from(e);
      msg['sender_name'] = e['sender']?['display_name'];
      msg['sender_avatar_url'] = e['sender']?['avatar_url'];
      return MessageModel.fromJson(msg);
    }).toList();
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String conversationId) {
    return _db
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at');
  }

  // ==================== DATABASE CLEANUP ====================

  /// Clear all rooms and their participants
  Future<void> clearAllRooms() async {
    try {
      // First delete all participants
      await _db.from('room_participants').delete().neq('id', '');
      // Then delete all rooms
      await _db.from('rooms').delete().neq('id', '');
      print('DatabaseService: All rooms cleared');
    } catch (e) {
      print('DatabaseService: Error clearing rooms: $e');
      rethrow;
    }
  }

  /// Clear all room participants only
  Future<void> clearAllRoomParticipants() async {
    try {
      await _db.from('room_participants').delete().neq('id', '');
      print('DatabaseService: All room participants cleared');
    } catch (e) {
      print('DatabaseService: Error clearing room participants: $e');
      rethrow;
    }
  }

  /// Clear all messages
  Future<void> clearAllMessages() async {
    try {
      await _db.from('messages').delete().neq('id', '');
      print('DatabaseService: All messages cleared');
    } catch (e) {
      print('DatabaseService: Error clearing messages: $e');
      rethrow;
    }
  }

  /// Clear all conversations and their members
  Future<void> clearAllConversations() async {
    try {
      // First delete all messages
      await _db.from('messages').delete().neq('id', '');
      // Then delete all conversation members
      await _db.from('conversation_members').delete().neq('id', '');
      // Then delete all conversations
      await _db.from('conversations').delete().neq('id', '');
      print('DatabaseService: All conversations cleared');
    } catch (e) {
      print('DatabaseService: Error clearing conversations: $e');
      rethrow;
    }
  }

  /// Clear all followers
  Future<void> clearAllFollowers() async {
    try {
      await _db.from('followers').delete().neq('id', '');
      print('DatabaseService: All followers cleared');
    } catch (e) {
      print('DatabaseService: Error clearing followers: $e');
      rethrow;
    }
  }

  /// Clear ALL data (rooms, messages, conversations, followers) - USE WITH CAUTION
  Future<void> clearAllData() async {
    try {
      await clearAllRooms();
      await clearAllConversations();
      await clearAllFollowers();
      print('DatabaseService: All data cleared');
    } catch (e) {
      print('DatabaseService: Error clearing all data: $e');
      rethrow;
    }
  }
}
