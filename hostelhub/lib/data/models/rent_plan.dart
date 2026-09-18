/// A recurring rent plan for one inmate: amount, due day, autopay, late fee.
class RentPlan {
  final String id;
  final String inmateId;
  /// Rent amount in whole rupees (convert to paise at the gateway).
  final int amount;
  /// Day of month rent is due (1-31).
  final int dueDay;
  final int graceDays;
  /// e.g. "flat:100" | "percent:2" | "per_day:50"
  final String? lateFeeRule;
  final bool autopayEnabled;
  /// Razorpay eMandate id once authorized.
  final String? mandateId;

  const RentPlan({
    required this.id,
    required this.inmateId,
    required this.amount,
    required this.dueDay,
    this.graceDays = 0,
    this.lateFeeRule,
    this.autopayEnabled = false,
    this.mandateId,
  });

  factory RentPlan.fromJson(Map<String, dynamic> json) => RentPlan(
        id: json['id'] as String,
        inmateId: json['inmate_id'] as String,
        amount: json['amount'] as int,
        dueDay: json['due_day'] as int,
        graceDays: json['grace_days'] as int? ?? 0,
        lateFeeRule: json['late_fee_rule'] as String?,
        autopayEnabled: json['autopay_enabled'] as bool? ?? false,
        mandateId: json['mandate_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'inmate_id': inmateId,
        'amount': amount,
        'due_day': dueDay,
        'grace_days': graceDays,
        'late_fee_rule': lateFeeRule,
        'autopay_enabled': autopayEnabled,
        'mandate_id': mandateId,
      };
}
