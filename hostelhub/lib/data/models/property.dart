/// A property an owner manages: hostel, PG, rental house, or office space.
/// `type` drives which features are relevant; `features` is an owner-controlled
/// on/off map (e.g. `mess`) that gates what inmates can see.
class Property {
  final String id;
  final String ownerId;
  final String name;
  final String? address;

  /// hostel | pg | house | office
  final String type;

  /// Owner-controlled feature toggles, e.g. {mess: true}.
  final Map<String, bool> features;

  /// e.g. [{room_type: 'single', amount: 7000}, ...]
  final List<Map<String, dynamic>> rentSlabs;

  /// e.g. {monthly: 2500, per_meal: 80}
  final Map<String, dynamic> messCharges;

  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.type = 'hostel',
    this.features = const {'mess': true},
    this.rentSlabs = const [],
    this.messCharges = const {},
  });

  /// Whether a feature (e.g. 'mess') is enabled for this property.
  bool featureEnabled(String key) => features[key] ?? false;

  /// Mess/polls is the differentiator: relevant only to hostels & PGs.
  bool get isHostelOrPg => type == 'hostel' || type == 'pg';

  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        address: json['address'] as String?,
        type: json['type'] as String? ?? 'hostel',
        features: Map<String, bool>.from(
            json['features'] as Map? ?? const {'mess': true}),
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
        'type': type,
        'features': features,
        'rent_slabs': rentSlabs,
        'mess_charges': messCharges,
      };
}
