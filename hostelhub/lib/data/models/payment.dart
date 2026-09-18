/// A single rent/extras payment record.
enum PaymentStatus { pending, paid, failed, refunded }

class Payment {
  final String id;
  final String inmateId;
  final int amount;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final PaymentStatus status;
  /// upi | card | netbanking | autopay
  final String? method;
  final String? receiptUrl;

  const Payment({
    required this.id,
    required this.inmateId,
    required this.amount,
    this.dueDate,
    this.paidDate,
    this.status = PaymentStatus.pending,
    this.method,
    this.receiptUrl,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        inmateId: json['inmate_id'] as String,
        amount: json['amount'] as int,
        dueDate: json['due_date'] != null
            ? DateTime.tryParse(json['due_date'] as String)
            : null,
        paidDate: json['paid_date'] != null
            ? DateTime.tryParse(json['paid_date'] as String)
            : null,
        status: PaymentStatus.values.byName(json['status'] as String),
        method: json['method'] as String?,
        receiptUrl: json['receipt_url'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'inmate_id': inmateId,
        'amount': amount,
        'due_date': dueDate?.toIso8601String(),
        'paid_date': paidDate?.toIso8601String(),
        'status': status.name,
        'method': method,
        'receipt_url': receiptUrl,
      };
}
