/// A checkout / vacate request initiated by the owner (or inmate).
class CheckoutRequest {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName;
  final String vacateDate;
  final String status; // requested | completed

  const CheckoutRequest({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    required this.vacateDate,
    this.status = 'requested',
  });

  factory CheckoutRequest.fromJson(Map<String, dynamic> json) =>
      CheckoutRequest(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        vacateDate: json['vacate_date'] as String,
        status: json['status'] as String? ?? 'requested',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'vacate_date': vacateDate,
        'status': status,
      };
}
