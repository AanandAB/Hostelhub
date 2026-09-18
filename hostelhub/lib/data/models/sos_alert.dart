/// An emergency SOS alert raised by an inmate.
class SosAlert {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName;
  final String? triggeredAt;
  final bool acknowledged;

  const SosAlert({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    this.triggeredAt,
    this.acknowledged = false,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) => SosAlert(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        triggeredAt: json['triggered_at'] as String?,
        acknowledged: json['acknowledged'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'triggered_at': triggeredAt,
        'acknowledged': acknowledged,
      };
}
