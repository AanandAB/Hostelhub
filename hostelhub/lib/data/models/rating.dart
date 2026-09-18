/// An inmate's rating of their stay.
class Rating {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName;
  final int stars; // 1-5
  final String comment;
  final String? createdAt;

  const Rating({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    required this.stars,
    this.comment = '',
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) => Rating(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        stars: json['stars'] as int,
        comment: json['comment'] as String? ?? '',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'stars': stars,
        'comment': comment,
        'created_at': createdAt,
      };
}
