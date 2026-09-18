/// A room within a property, holding one or more beds.
class Room {
  final String id;
  final String propertyId;
  final String roomNo;
  final int capacity;

  const Room({
    required this.id,
    required this.propertyId,
    required this.roomNo,
    required this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        roomNo: json['room_no'] as String,
        capacity: json['capacity'] as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'room_no': roomNo,
        'capacity': capacity,
      };
}
