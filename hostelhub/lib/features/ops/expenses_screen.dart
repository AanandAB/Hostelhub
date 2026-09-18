import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/expense.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

const kExpenseCategories = [
  'groceries',
  'salary',
  'electricity',
  'water',
  'maintenance',
  'misc'
];

/// Owner: income vs expense (P&L) + expense log.
class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses & P&L'),
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
    final pnl = ref.watch(pnlProvider(propertyId)).value;
    final expenses =
        ref.watch(expensesProvider(propertyId)).value ?? const <Expense>[];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        if (pnl != null)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profit & loss', style: textTheme.titleLarge),
                const SizedBox(height: 12),
                _pnlRow(context, 'Income (rent)', '+ ₹${pnl.income}',
                    AppColors.accent),
                const SizedBox(height: 6),
                _pnlRow(context, 'Expenses', '− ₹${pnl.expense}',
                    AppColors.danger),
                const Divider(height: 20),
                _pnlRow(context, 'Net', '${pnl.net >= 0 ? '+' : '−'} ₹${pnl.net.abs()}',
                    pnl.net >= 0 ? AppColors.accent : AppColors.danger),
              ],
            ),
          ),
        const SizedBox(height: 16),
        GlassButton(
          label: 'Add expense',
          icon: Icons.add_rounded,
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _AddExpenseDialog(propertyId: propertyId),
          ),
        ),
        const SizedBox(height: 20),
        if (expenses.isEmpty)
          Center(child: Text('No expenses logged.', style: textTheme.bodyMedium))
        else
          for (final e in expenses.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.category, style: textTheme.titleMedium),
                          Text('${e.date}${e.notes.isNotEmpty ? ' · ${e.notes}' : ''}',
                              style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Text('− ₹${e.amount}', style: textTheme.titleMedium),
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _pnlRow(BuildContext context, String label, String value, Color color) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value,
            style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _AddExpenseDialog extends ConsumerStatefulWidget {
  final String propertyId;
  const _AddExpenseDialog({required this.propertyId});

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'groceries';
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (amount <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createExpense(Expense(
            id: '',
            propertyId: widget.propertyId,
            category: _category,
            amount: amount,
            date: DateTime.now().toIso8601String().substring(0, 10),
            notes: _notes.text.trim(),
          ));
      ref.invalidate(expensesProvider(widget.propertyId));
      ref.invalidate(pnlProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not add: $e')));
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
            Text('Add expense', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in kExpenseCategories)
                  _chip(c, _category == c, () => setState(() => _category = c)),
              ],
            ),
            const SizedBox(height: 16),
            GlassTextField(
                controller: _amount,
                label: 'Amount (₹)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _notes,
                label: 'Notes (optional)',
                icon: Icons.notes_outlined),
            const SizedBox(height: 16),
            GlassButton(label: 'Save', loading: _busy, onPressed: _save),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? primary.withValues(alpha: 0.18)
              : (isDark ? AppColors.glassDark : AppColors.glassLight),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? primary : muted)),
      ),
    );
  }
}
