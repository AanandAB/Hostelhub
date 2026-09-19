import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/checkout_request.dart';
import '../../data/models/deposit.dart';
import '../../data/models/inmate.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

/// Owner: security deposits — record, deduct, view refundable.
class DepositsScreen extends ConsumerWidget {
  const DepositsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposits'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(
                    child: Text('Set up your hostel first.',
                        style: textTheme.bodyMedium))
                : _content(context, ref, prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, String propertyId,
      TextTheme textTheme) {
    final deposits =
        ref.watch(depositsProvider(propertyId)).value ?? const <Deposit>[];
    final inmates = ref.watch(inmatesProvider(propertyId)).value ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        GlassButton(
          label: 'Record deposit',
          icon: Icons.add_rounded,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _RecordDepositDialog(propertyId: propertyId, inmates: inmates),
          ),
        ),
        const SizedBox(height: 20),
        if (deposits.isEmpty)
          Center(child: Text('No deposits recorded.', style: textTheme.bodyMedium))
        else
          for (final d in deposits)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DepositCard(deposit: d, propertyId: propertyId),
            ),
      ],
    );
  }
}

class _DepositCard extends ConsumerWidget {
  final Deposit deposit;
  final String propertyId;
  const _DepositCard({required this.deposit, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(deposit.inmateName, style: textTheme.titleMedium)),
              Text('₹${deposit.refundable} refundable',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Collected ₹${deposit.amountCollected} · Deducted ₹${deposit.deductionsTotal}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => _DeductDialog(depositId: deposit.id, propertyId: propertyId),
            ),
            child: const Text('Add deduction'),
          ),
        ],
      ),
    );
  }
}

/// Inmate: view own security deposit.
class DepositViewScreen extends ConsumerWidget {
  const DepositViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final deposit = ref.watch(inmateDepositProvider(user?.id ?? '')).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My deposit'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: deposit == null
              ? Center(
                  child: Text('No deposit recorded yet.',
                      style: textTheme.bodyMedium))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Security deposit', style: textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _row(context, 'Collected', '₹${deposit.amountCollected}'),
                          const SizedBox(height: 6),
                          _row(context, 'Deductions', '− ₹${deposit.deductionsTotal}'),
                          const Divider(height: 20),
                          _row(context, 'Refundable', '₹${deposit.refundable}'),
                        ],
                      ),
                    ),
                  ],
                ),
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

/// Owner: checkout / vacate requests.
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(
                    child: Text('Set up your hostel first.',
                        style: textTheme.bodyMedium))
                : _content(context, ref, prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, String propertyId,
      TextTheme textTheme) {
    final checkouts = ref.watch(checkoutsProvider(propertyId)).value ??
        const <CheckoutRequest>[];
    final inmates = ref.watch(inmatesProvider(propertyId)).value ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        GlassButton(
          label: 'Initiate checkout',
          icon: Icons.logout_rounded,
          onPressed: () => showDialog(
            context: context,
            builder: (_) =>
                _InitiateCheckoutDialog(propertyId: propertyId, inmates: inmates),
          ),
        ),
        const SizedBox(height: 20),
        if (checkouts.isEmpty)
          Center(child: Text('No checkouts yet.', style: textTheme.bodyMedium))
        else
          for (final c in checkouts)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.inmateName, style: textTheme.titleMedium),
                              Text('Vacating ${c.vacateDate}',
                                  style: textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Text(c.status,
                            style: TextStyle(
                                color: c.status == 'completed'
                                    ? AppColors.accent
                                    : AppColors.warning,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                    if (c.status == 'requested') ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => _CompleteCheckoutDialog(
                            propertyId: propertyId,
                            checkout: c,
                          ),
                        ),
                        child:
                            const Text('Complete checkout & settle deposit'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────────

class _RecordDepositDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final List<Inmate> inmates;
  const _RecordDepositDialog(
      {required this.propertyId, required this.inmates});

  @override
  ConsumerState<_RecordDepositDialog> createState() =>
      _RecordDepositDialogState();
}

class _RecordDepositDialogState extends ConsumerState<_RecordDepositDialog> {
  final _amount = TextEditingController();
  String? _inmateId;
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_inmateId == null || amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createDeposit(Deposit(
            id: '',
            propertyId: widget.propertyId,
            inmateId: _inmateId!,
            amountCollected: amount,
          ));
      ref.invalidate(depositsProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not record: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Record deposit', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            InmatePicker(
                inmates: widget.inmates,
                selectedId: _inmateId,
                onSelect: (id) => setState(() => _inmateId = id)),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _amount,
                label: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            GlassButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _DeductDialog extends ConsumerStatefulWidget {
  final String depositId;
  final String propertyId;
  const _DeductDialog({required this.depositId, required this.propertyId});

  @override
  ConsumerState<_DeductDialog> createState() => _DeductDialogState();
}

class _DeductDialogState extends ConsumerState<_DeductDialog> {
  final _reason = TextEditingController();
  final _amount = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_reason.text.trim().isEmpty || amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.addDepositDeduction(
          widget.depositId, _reason.text.trim(), amount);
      ref.invalidate(depositsProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not deduct: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add deduction', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            GlassTextField(
                controller: _reason,
                label: 'Reason',
                icon: Icons.notes_outlined),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _amount,
                label: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            GlassButton(label: 'Deduct', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _InitiateCheckoutDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final List<Inmate> inmates;
  const _InitiateCheckoutDialog(
      {required this.propertyId, required this.inmates});

  @override
  ConsumerState<_InitiateCheckoutDialog> createState() =>
      _InitiateCheckoutDialogState();
}

class _InitiateCheckoutDialogState
    extends ConsumerState<_InitiateCheckoutDialog> {
  final _date = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10));
  String? _inmateId;
  bool _busy = false;

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_inmateId == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createCheckout(CheckoutRequest(
            id: '',
            propertyId: widget.propertyId,
            inmateId: _inmateId!,
            vacateDate: _date.text.trim(),
          ));
      ref.invalidate(checkoutsProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not initiate: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Initiate checkout', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            InmatePicker(
                inmates: widget.inmates,
                selectedId: _inmateId,
                onSelect: (id) => setState(() => _inmateId = id)),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _date,
                label: 'Vacate date (YYYY-MM-DD)',
                icon: Icons.event_rounded),
            const SizedBox(height: 16),
            GlassButton(label: 'Initiate', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _CompleteCheckoutDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final CheckoutRequest checkout;
  const _CompleteCheckoutDialog(
      {required this.propertyId, required this.checkout});

  @override
  ConsumerState<_CompleteCheckoutDialog> createState() =>
      _CompleteCheckoutDialogState();
}

class _CompleteCheckoutDialogState
    extends ConsumerState<_CompleteCheckoutDialog> {
  final _refund = TextEditingController(text: '0');
  final _forfeit = TextEditingController(text: '0');
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    _refund.dispose();
    _forfeit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final refund = int.tryParse(_refund.text.trim()) ?? 0;
    final forfeit = int.tryParse(_forfeit.text.trim()) ?? 0;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.completeCheckout(
            widget.checkout.id,
            refund: refund,
            forfeit: forfeit,
          );
      ref.invalidate(checkoutsProvider(widget.propertyId));
      ref.invalidate(inmatesProvider(widget.propertyId));
      ref.invalidate(depositsProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not complete: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final deposit =
        ref.watch(inmateDepositProvider(widget.checkout.inmateId)).value;
    // Auto-fill the refund with the deposit's refundable balance once loaded,
    // so the owner settles against the inmate's actual deposit + deductions.
    if (!_seeded && deposit != null) {
      _seeded = true;
      _refund.text = '${deposit.refundable}';
    }
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassCard(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Complete checkout', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                  '${widget.checkout.inmateName} · vacating ${widget.checkout.vacateDate}',
                  style: textTheme.bodyMedium),
              if (deposit != null) ...[
                const SizedBox(height: 12),
                _depositSummary(context, deposit, textTheme),
              ],
              const SizedBox(height: 12),
              GlassTextField(
                  controller: _refund,
                  label: 'Refund amount (₹)',
                  icon: Icons.currency_rupee,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              GlassTextField(
                  controller: _forfeit,
                  label: 'Additional forfeit for damages (₹)',
                  icon: Icons.report_rounded,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              GlassButton(label: 'Complete', loading: _busy, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }

  /// Itemised deposit breakdown (collected − deductions = refundable), so the
  /// owner sees exactly what's being settled at checkout.
  Widget _depositSummary(
      BuildContext context, Deposit d, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deposit summary', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          _sumRow(context, 'Collected', '₹${d.amountCollected}'),
          for (final ded in d.deductions)
            _sumRow(context,
                '− ${ded['reason'] ?? 'Deduction'}', '₹${ded['amount'] ?? 0}'),
          const Divider(height: 16),
          _sumRow(context, 'Refundable', '₹${d.refundable}',
              highlight: true),
        ],
      ),
    );
  }

  Widget _sumRow(BuildContext context, String label, String value,
      {bool highlight = false}) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value,
              style: highlight
                  ? textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700, color: AppColors.accent)
                  : textTheme.bodyLarge?.copyWith(color: muted)),
        ],
      ),
    );
  }
}

/// Shared chip-selector for picking an inmate.
class InmatePicker extends StatelessWidget {
  final List<Inmate> inmates;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  const InmatePicker(
      {super.key,
      required this.inmates,
      required this.selectedId,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    if (inmates.isEmpty) {
      return Text('No inmates yet.', style: Theme.of(context).textTheme.bodySmall);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final i in inmates)
          GestureDetector(
            onTap: () => onSelect(i.id),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: i.id == selectedId
                    ? primary.withValues(alpha: 0.18)
                    : (isDark ? AppColors.glassDark : AppColors.glassLight),
                border: Border.all(
                    color: i.id == selectedId ? primary : Colors.transparent),
              ),
              child: Text(i.name,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: i.id == selectedId ? primary : muted)),
            ),
          ),
      ],
    );
  }
}
