import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/payment.dart';
import '../../data/models/rent_plan.dart';

final rentPlanProvider = FutureProvider.family<RentPlan?, String>(
    (ref, inmateId) => ref.watch(backendProvider).rent.getRentPlan(inmateId));

final paymentsProvider = FutureProvider.family<List<Payment>, String>(
    (ref, inmateId) => ref.watch(backendProvider).rent.listPayments(inmateId));

/// All payments for a property (owner dashboard / bills).
final propertyPaymentsProvider =
    FutureProvider.family<List<Payment>, String>((ref, propertyId) =>
        ref.watch(backendProvider).rent.listPropertyPayments(propertyId));

/// Days until the next occurrence of `dueDay` (negative = overdue).
int daysUntilDue(int dueDay, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  var due = DateTime(n.year, n.month, dueDay);
  if (due.isBefore(today)) {
    due = DateTime(n.year, n.month + 1, dueDay);
  }
  return due.difference(today).inDays;
}

/// True if the inmate has a paid payment dated in the current month.
bool paidThisMonth(List<Payment> payments, {DateTime? now}) {
  final n = now ?? DateTime.now();
  return payments.any((p) =>
      p.status == PaymentStatus.paid &&
      p.paidDate != null &&
      p.paidDate!.year == n.year &&
      p.paidDate!.month == n.month);
}
