/// An inmate's leave / going-home record.
class LeaveRecord {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName;
  final String startDate;
  final String endDate;
  final String reason;
  final String status; // on_leave | returned

  const LeaveRecord({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    required this.startDate,
    required this.endDate,
    this.reason = '',
    this.status = 'on_leave',
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) => LeaveRecord(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        startDate: json['start_date'] as String,
        endDate: json['end_date'] as String,
        reason: json['reason'] as String? ?? '',
        status: json['status'] as String? ?? 'on_leave',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        'status': status,
      };
}
