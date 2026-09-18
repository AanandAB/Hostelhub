/// One message in an inmate↔owner chat thread.
class ChatMessage {
  final String id;
  final String inmateId; // the thread key
  final String senderId;
  final String senderRole; // owner | inmate
  final String text;
  final String? sentAt;

  const ChatMessage({
    required this.id,
    required this.inmateId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        inmateId: json['inmate_id'] as String,
        senderId: json['sender_id'] as String,
        senderRole: json['sender_role'] as String,
        text: json['text'] as String,
        sentAt: json['sent_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'inmate_id': inmateId,
        'sender_id': senderId,
        'sender_role': senderRole,
        'text': text,
        'sent_at': sentAt,
      };
}
