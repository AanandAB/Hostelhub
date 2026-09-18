/// A visitor logged at the front desk.
class Visitor {
  final String id;
  final String propertyId;
  final String name;
  final String phone;
  final String purpose;
  final String visitingInmateName;
  final String? inTime;
  final String? outTime; // null = still inside

  const Visitor({
    required this.id,
    required this.propertyId,
    required this.name,
    this.phone = '',
    this.purpose = '',
    this.visitingInmateName = '',
    this.inTime,
    this.outTime,
  });

  bool get isInside => outTime == null;

  factory Visitor.fromJson(Map<String, dynamic> json) => Visitor(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        purpose: json['purpose'] as String? ?? '',
        visitingInmateName: json['visiting_inmate_name'] as String? ?? '',
        inTime: json['in_time'] as String?,
        outTime: json['out_time'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'name': name,
        'phone': phone,
        'purpose': purpose,
        'visiting_inmate_name': visitingInmateName,
        'in_time': inTime,
        'out_time': outTime,
      };
}
