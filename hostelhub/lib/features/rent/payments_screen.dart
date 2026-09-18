import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import 'pay_flow.dart';
import 'rent_providers.dart';

/// Inmate "Payments" tab: rent summary + pay button + payment history.
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final inmateId = user?.id ?? '';
    final plan = ref.watch(rentPlanProvider(inmateId)).value;
    final payments =
        ref.watch(paymentsProvider(inmateId)).value ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    final paid = plan == null ? false : paidThisMonth(payments);

    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text('Payments', style: textTheme.displayLarge),
            const SizedBox(height: 20),
            if (plan != null)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This month', style: textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text('₹${plan.amount}/mo', style: textTheme.displayLarge),
                    const SizedBox(height: 4),
                    Text(
                      paid ? 'Paid ✓' : 'Due on day ${plan.dueDay}',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      label:
                          paid ? 'Paid ✓' : 'Pay rent ₹${plan.amount}',
                      onPressed: paid
                          ? null
                          : () => payRentAndShowReceipt(
                              context, ref, inmateId, plan.amount),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Text('History', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            if (payments.isEmpty)
              Text('No payments yet.', style: textTheme.bodyMedium)
            else
              for (final p in payments.reversed)
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.16),
                        ),
                        child: const Icon(Icons.receipt_long_rounded,
                            size: 20, color: AppColors.accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.paidDate
                                      ?.toIso8601String()
                                      .substring(0, 10) ??
                                  '—',
                              style: textTheme.titleMedium,
                            ),
                            Text(
                              p.status.name.toUpperCase(),
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Text('₹${p.amount}', style: textTheme.titleMedium),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            if (payments.isNotEmpty)
              Center(
                child: Text(
                  'Receipts are auto-generated for every payment.',
                  style: textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
