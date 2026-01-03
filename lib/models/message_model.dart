enum MessageType { text, image, audio, system }

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderName;
  final String? senderAvatarUrl;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderName,
    this.senderAvatarUrl,
    required this.content,
    this.type = MessageType.text,
    required this.createdAt,
    this.isRead = false,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String?,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      content: json['content'] as String,
      type: _parseType(json['message_type'] as String? ?? json['type'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  static MessageType _parseType(String? type) {
    switch (type) {
      case 'image':
        return MessageType.image;
      case 'audio':
        return MessageType.audio;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'type': type.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderAvatarUrl,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatarUrl: senderAvatarUrl ?? this.senderAvatarUrl,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  bool get isTextMessage => type == MessageType.text;
  bool get isImageMessage => type == MessageType.image;
  bool get isSystemMessage => type == MessageType.system;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ConversationModel {
  final String id;
  final String type; // 'direct', 'group', 'room'
  final String? roomId;
  final String? name;
  final String? avatarUrl;
  final List<String> memberIds;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.type,
    this.roomId,
    this.name,
    this.avatarUrl,
    this.memberIds = const [],
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      roomId: json['room_id'] as String?,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      memberIds: (json['member_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'room_id': roomId,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isDirect => type == 'direct';
  bool get isGroup => type == 'group';
  bool get isRoomChat => type == 'room';
  bool get hasUnread => unreadCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
