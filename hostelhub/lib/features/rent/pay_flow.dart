import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/payment.dart';
import '../../presentation/widgets/glass.dart';
import 'rent_providers.dart';

/// Runs the manual-rent payment and shows the receipt. Returns true on success.
/// On the local backend the charge is simulated; live Razorpay checkout is
/// wired once keys exist (see payment_gateway.dart).
Future<bool> payRentAndShowReceipt(
  BuildContext context,
  WidgetRef ref,
  String inmateId,
  int amount,
) async {
  try {
    final payment = await ref.read(backendProvider).rent.payRent(
          inmateId: inmateId,
          amount: amount,
          dueDate: DateTime.now().toIso8601String().substring(0, 10),
        );
    ref.invalidate(paymentsProvider(inmateId));
    ref.invalidate(rentPlanProvider(inmateId));
    if (!context.mounted) return true;
    await showDialog(
      context: context,
      builder: (_) => ReceiptDialog(payment: payment),
    );
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
    return false;
  }
}

/// Success dialog showing the digital receipt for a completed payment.
class ReceiptDialog extends StatelessWidget {
  final Payment payment;
  const ReceiptDialog({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 40, color: AppColors.accent),
            const SizedBox(height: 12),
            Text('Payment successful', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            _row(context, 'Amount', '₹${payment.amount}'),
            const SizedBox(height: 8),
            _row(context, 'Date',
                payment.paidDate?.toIso8601String().substring(0, 10) ?? '—'),
            const SizedBox(height: 8),
            _row(context, 'Method', (payment.method ?? 'upi').toUpperCase()),
            const SizedBox(height: 8),
            _row(context, 'Receipt', payment.receiptUrl ?? '—'),
            const SizedBox(height: 20),
            GlassButton(
              label: 'Done',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.bodyLarge),
      ],
    );
  }
}
