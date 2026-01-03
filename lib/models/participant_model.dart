enum ParticipantRole { host, speaker, listener }

class ParticipantModel {
  final String odiumId;
  final String odiumName;
  final String? avatarUrl;
  final ParticipantRole role;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool hasRaisedHand;
  final DateTime joinedAt;

  ParticipantModel({
    required this.odiumId,
    required this.odiumName,
    this.avatarUrl,
    this.role = ParticipantRole.listener,
    this.isMuted = true,
    this.isVideoEnabled = false,
    this.hasRaisedHand = false,
    required this.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      odiumId: json['user_id'] as String,
      odiumName: json['user_name'] as String? ?? 'Unknown',
      avatarUrl: json['avatar_url'] as String?,
      role: _parseRole(json['role'] as String?),
      isMuted: json['is_muted'] as bool? ?? true,
      isVideoEnabled: json['is_video_enabled'] as bool? ?? false,
      hasRaisedHand: json['has_raised_hand'] as bool? ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : DateTime.now(),
    );
  }

  static ParticipantRole _parseRole(String? role) {
    switch (role) {
      case 'host':
        return ParticipantRole.host;
      case 'speaker':
        return ParticipantRole.speaker;
      default:
        return ParticipantRole.listener;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': odiumId,
      'user_name': odiumName,
      'avatar_url': avatarUrl,
      'role': role.name,
      'is_muted': isMuted,
      'is_video_enabled': isVideoEnabled,
      'has_raised_hand': hasRaisedHand,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  ParticipantModel copyWith({
    String? odiumId,
    String? odiumName,
    String? avatarUrl,
    ParticipantRole? role,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? hasRaisedHand,
    DateTime? joinedAt,
  }) {
    return ParticipantModel(
      odiumId: odiumId ?? this.odiumId,
      odiumName: odiumName ?? this.odiumName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      hasRaisedHand: hasRaisedHand ?? this.hasRaisedHand,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  bool get isHost => role == ParticipantRole.host;
  bool get isSpeaker => role == ParticipantRole.speaker || role == ParticipantRole.host;
  bool get isListener => role == ParticipantRole.listener;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantModel &&
          runtimeType == other.runtimeType &&
          odiumId == other.odiumId;

  @override
  int get hashCode => odiumId.hashCode;
}
