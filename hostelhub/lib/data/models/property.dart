/// A hostel / PG owned by an owner. Supports multi-property portfolios.
class Property {
  final String id;
  final String ownerId;
  final String name;
  final String? address;
  /// e.g. [{room_type: 'single', amount: 7000}, ...]
  final List<Map<String, dynamic>> rentSlabs;
  /// e.g. {monthly: 2500, per_meal: 80}
  final Map<String, dynamic> messCharges;

  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.rentSlabs = const [],
    this.messCharges = const {},
  });

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        rentSlabs: List<Map<String, dynamic>>.from(
            json['rent_slabs'] as List? ?? const []),
        messCharges:
            json['mess_charges'] as Map<String, dynamic>? ?? const {},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_id': ownerId,
        'name': name,
        'address': address,
        'rent_slabs': rentSlabs,
        'mess_charges': messCharges,
      };
}
