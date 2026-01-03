import 'participant_model.dart';

enum RoomType { audio, video }

class RoomModel {
  final String id;
  final String title;
  final String? description;
  final String hostId;
  final String? hostName;
  final String? hostAvatarUrl;
  final RoomType type;
  final bool isLive;
  final int maxParticipants;
  final int participantsCount;
  final List<ParticipantModel> speakers;
  final List<ParticipantModel> listeners;
  final DateTime createdAt;

  RoomModel({
    required this.id,
    required this.title,
    this.description,
    required this.hostId,
    this.hostName,
    this.hostAvatarUrl,
    this.type = RoomType.audio,
    this.isLive = false,
    this.maxParticipants = 12,
    this.participantsCount = 0,
    this.speakers = const [],
    this.listeners = const [],
    required this.createdAt,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      hostId: json['host_id'] as String,
      hostName: json['host_name'] as String?,
      hostAvatarUrl: json['host_avatar_url'] as String?,
      type: json['type'] == 'video' ? RoomType.video : RoomType.audio,
      isLive: json['is_live'] as bool? ?? false,
      maxParticipants: json['max_participants'] as int? ?? 12,
      participantsCount: json['participants_count'] as int? ?? 0,
      speakers: (json['speakers'] as List<dynamic>?)
              ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      listeners: (json['listeners'] as List<dynamic>?)
              ?.map((e) => ParticipantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'host_id': hostId,
      'type': type == RoomType.video ? 'video' : 'audio',
      'is_live': isLive,
      'max_participants': maxParticipants,
      'created_at': createdAt.toIso8601String(),
    };
  }

  RoomModel copyWith({
    String? id,
    String? title,
    String? description,
    String? hostId,
    String? hostName,
    String? hostAvatarUrl,
    RoomType? type,
    bool? isLive,
    int? maxParticipants,
    int? participantsCount,
    List<ParticipantModel>? speakers,
    List<ParticipantModel>? listeners,
    DateTime? createdAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostAvatarUrl: hostAvatarUrl ?? this.hostAvatarUrl,
      type: type ?? this.type,
      isLive: isLive ?? this.isLive,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      participantsCount: participantsCount ?? this.participantsCount,
      speakers: speakers ?? this.speakers,
      listeners: listeners ?? this.listeners,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isAudioRoom => type == RoomType.audio;
  bool get isVideoRoom => type == RoomType.video;
  bool get isFull => participantsCount >= maxParticipants;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
