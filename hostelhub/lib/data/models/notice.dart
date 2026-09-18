/// A notice-board announcement posted by the owner/warden.
class Notice {
  final String id;
  final String propertyId;
  final String title;
  final String body;
  final String category; // general | mess | maintenance | emergency
  final bool pinned;
  final String? createdAt;

  const Notice({
    required this.id,
    required this.propertyId,
    required this.title,
    this.body = '',
    this.category = 'general',
    this.pinned = false,
    this.createdAt,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        title: json['title'] as String,
        body: json['body'] as String? ?? '',
        category: json['category'] as String? ?? 'general',
        pinned: json['pinned'] as bool? ?? false,
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'title': title,
        'body': body,
        'category': category,
        'pinned': pinned,
        'created_at': createdAt,
      };
}
