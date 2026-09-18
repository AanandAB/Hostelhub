/// A document in the vault: rental agreement, house rules, or KYC.
/// Metadata only for now — real file storage lands with the production backend.
class Document {
  final String id;
  final String ownerType; // hostel | inmate
  final String ownerId; // property id (hostel) or inmate id
  final String name;
  final String type; // agreement | rules | id_proof | other
  final String? fileUrl;
  final String? uploadedAt;

  const Document({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.name,
    this.type = 'other',
    this.fileUrl,
    this.uploadedAt,
  });

  factory Document.fromJson(Map<String, dynamic> json) => Document(
        id: json['id'] as String,
        ownerType: json['owner_type'] as String,
        ownerId: json['owner_id'] as String,
        name: json['name'] as String,
        type: json['type'] as String? ?? 'other',
        fileUrl: json['file_url'] as String?,
        uploadedAt: json['uploaded_at'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'owner_type': ownerType,
        'owner_id': ownerId,
        'name': name,
        'type': type,
        'file_url': fileUrl,
        'uploaded_at': uploadedAt,
      };
}
