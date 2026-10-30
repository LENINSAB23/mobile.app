class ChatMessageModel {
  final int? id;
  final int? conversationId;
  final String role; // 'user' or 'model'
  final String content;
  final DateTime createdAt;

  ChatMessageModel({
    this.id,
    this.conversationId,
    required this.role,
    required this.content,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == 'user';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id']
          : int.tryParse(json['conversation_id']?.toString() ?? ''),
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      'role': role,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
