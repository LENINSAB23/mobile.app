class ConversationModel {
  final int id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? lastMessage;
  final int messagesCount;

  ConversationModel({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
    this.lastMessage,
    this.messagesCount = 0,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    String? latestText;
    if (json['latest_message'] != null && json['latest_message'] is Map) {
      latestText = json['latest_message']['content'];
    }

    return ConversationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? 'Conversación',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
      lastMessage: latestText,
      messagesCount: json['messages_count'] is int ? json['messages_count'] : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_message': lastMessage,
      'messages_count': messagesCount,
    };
  }
}
