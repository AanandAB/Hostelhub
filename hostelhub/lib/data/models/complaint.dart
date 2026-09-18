/// A complaint / maintenance ticket raised by an inmate.
class Complaint {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName; // denormalized for display
  final String category; // electrical | plumbing | ac | cleaning | other
  final String description;
  final String status; // open | in_progress | resolved
  final String? createdAt;

  const Complaint({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    required this.category,
    required this.description,
    this.status = 'open',
    this.createdAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) => Complaint(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        category: json['category'] as String,
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? 'open',
        createdAt: json['created_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'category': category,
        'description': description,
        'status': status,
        'created_at': createdAt,
      };
}
