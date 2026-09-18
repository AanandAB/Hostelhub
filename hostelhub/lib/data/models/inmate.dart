/// An inmate (ward) onboarded by an owner: personal details plus their room/bed
/// assignment and rent terms.
class Inmate {
  final String id;
  final String propertyId;
  final String name;
  final String phone;
  final String username;
  final String roomId;
  final String roomNo;
  final int bedNo;
  final int rentAmount; // ₹ per month
  final int dueDay; // day of month rent is due (1-31)
  final String? joinDate;
  final String? checkoutDate; // set once the inmate checks out (stay history)

  const Inmate({
    required this.id,
    required this.propertyId,
    required this.name,
    this.phone = '',
    this.username = '',
    this.roomId = '',
    this.roomNo = '',
    this.bedNo = 1,
    this.rentAmount = 0,
    this.dueDay = 1,
    this.joinDate,
    this.checkoutDate,
  });

  factory Inmate.fromJson(Map<String, dynamic> json) => Inmate(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String? ?? '',
        username: json['username'] as String? ?? '',
        roomId: json['room_id'] as String? ?? '',
        roomNo: json['room_no'] as String? ?? '',
        bedNo: json['bed_no'] as int? ?? 1,
        rentAmount: json['rent_amount'] as int? ?? 0,
        dueDay: json['due_day'] as int? ?? 1,
        joinDate: json['join_date'] as String?,
        checkoutDate: json['checkout_date'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'name': name,
        'phone': phone,
        'username': username,
        'room_id': roomId,
        'room_no': roomNo,
        'bed_no': bedNo,
        'rent_amount': rentAmount,
        'due_day': dueDay,
        'join_date': joinDate,
        'checkout_date': checkoutDate,
      };
}
