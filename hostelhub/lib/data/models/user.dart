/// A person in the system: owner/manager, inmate/ward, or sub-manager.
enum UserRole { owner, inmate, subManager }

class User {
  final String id;
  final UserRole role;
  /// Hostel this user belongs to (null for an owner before onboarding).
  final String? propertyId;
  final String name;
  final String phone;
  final String username;
  final bool kycVerified;

  const User({
    required this.id,
    required this.role,
    this.propertyId,
    required this.name,
    required this.phone,
    required this.username,
    this.kycVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        role: UserRole.values.byName(json['role'] as String),
        propertyId: json['property_id'] as String?,
        name: json['name'] as String,
        phone: json['phone'] as String,
        username: json['username'] as String,
        kycVerified: json['kyc_verified'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role.name,
        'property_id': propertyId,
        'name': name,
        'phone': phone,
        'username': username,
        'kyc_verified': kycVerified,
      };
}
