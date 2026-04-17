class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? content;
  final String? mediaUrl;
  final String? mediaType;
  final bool isRead;
  final DateTime createdAt;

  const MessageModel({
    required this.id, required this.conversationId,
    required this.senderId, required this.senderName,
    this.content, this.mediaUrl, this.mediaType,
    this.isRead = false, required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => MessageModel(
    id: json['id'] as String,
    conversationId: json['conversation_id'] as String,
    senderId: json['sender_id'] as String,
    senderName: json['sender_name'] as String? ?? '',
    content: json['content'] as String?,
    mediaUrl: json['media_url'] as String?,
    mediaType: json['media_type'] as String?,
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'conversation_id': conversationId,
    'sender_id': senderId, 'sender_name': senderName,
    'content': content, 'media_url': mediaUrl, 'media_type': mediaType,
    'is_read': isRead, 'created_at': createdAt.toIso8601String(),
  };
}

class ConversationModel {
  final String id;
  final String patientId;
  final String doctorId;
  final String patientName;
  final String doctorName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  const ConversationModel({
    required this.id, required this.patientId, required this.doctorId,
    required this.patientName, required this.doctorName,
    this.lastMessage, this.lastMessageAt, this.unreadCount = 0,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
    id: json['id'] as String,
    patientId: json['patient_id'] as String,
    doctorId: json['doctor_id'] as String,
    patientName: json['patient_name'] as String? ?? '',
    doctorName: json['doctor_name'] as String? ?? '',
    lastMessage: json['last_message'] as String?,
    lastMessageAt: json['last_message_at'] != null ? DateTime.parse(json['last_message_at'] as String) : null,
    unreadCount: json['unread_count'] as int? ?? 0,
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}
