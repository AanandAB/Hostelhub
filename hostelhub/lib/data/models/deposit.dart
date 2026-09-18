/// An inmate's security deposit: amount collected minus any deductions.
class Deposit {
  final String id;
  final String propertyId;
  final String inmateId;
  final String inmateName;
  final int amountCollected;
  final List<Map<String, dynamic>> deductions; // [{reason, amount}]
  final String status; // held | refunded

  const Deposit({
    required this.id,
    required this.propertyId,
    required this.inmateId,
    this.inmateName = '',
    required this.amountCollected,
    this.deductions = const [],
    this.status = 'held',
  });

  int get deductionsTotal =>
      deductions.fold(0, (sum, d) => sum + ((d['amount'] as int?) ?? 0));

  int get refundable => amountCollected - deductionsTotal;

  factory Deposit.fromJson(Map<String, dynamic> json) => Deposit(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        inmateId: json['inmate_id'] as String,
        inmateName: json['inmate_name'] as String? ?? '',
        amountCollected: json['amount_collected'] as int? ?? 0,
        deductions: List<Map<String, dynamic>>.from(
            json['deductions'] as List? ?? const []),
        status: json['status'] as String? ?? 'held',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'inmate_id': inmateId,
        'inmate_name': inmateName,
        'amount_collected': amountCollected,
        'deductions': deductions,
        'status': status,
      };
}
