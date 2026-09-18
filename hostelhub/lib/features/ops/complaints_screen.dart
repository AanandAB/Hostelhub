import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/complaint.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

const kComplaintCategories = ['electrical', 'plumbing', 'ac', 'cleaning', 'other'];
const kComplaintStatuses = ['open', 'in_progress', 'resolved'];

/// Owner: triage complaints and advance their status.
class ComplaintsScreen extends ConsumerWidget {
  const ComplaintsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complaints'),
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
                : _list(context, ref, prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                const Center(child: Text('Error loading complaints')),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, String propertyId,
      TextTheme textTheme) {
    final complaints =
        ref.watch(complaintsProvider(propertyId)).value ?? const <Complaint>[];
    if (complaints.isEmpty) {
      return Center(child: Text('No complaints yet.', style: textTheme.bodyMedium));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        for (final c in complaints)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ComplaintCard(complaint: c, propertyId: propertyId),
          ),
      ],
    );
  }
}

class _ComplaintCard extends ConsumerWidget {
  final Complaint complaint;
  final String propertyId;
  const _ComplaintCard({required this.complaint, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final color = complaintStatusColor(complaint.status);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(complaint.category,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
              const Spacer(),
              Text(complaint.status.replaceAll('_', ' '),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(complaint.description, style: textTheme.bodyLarge),
          const SizedBox(height: 4),
          Text(
            '${complaint.inmateName} · ${complaint.createdAt?.substring(0, 10) ?? ''}',
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final s in kComplaintStatuses)
                if (s != complaint.status)
                  _statusChip(context, s, () async {
                    await ref
                        .read(backendProvider)
                        .ops
                        .updateComplaintStatus(complaint.id, s);
                    ref.invalidate(complaintsProvider(propertyId));
                  }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context, String status, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5)),
        ),
        child: Text('Mark ${status.replaceAll('_', ' ')}',
            style: TextStyle(fontSize: 12, color: muted)),
      ),
    );
  }
}

/// Inmate: raise a complaint.
class RaiseComplaintScreen extends ConsumerStatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  ConsumerState<RaiseComplaintScreen> createState() =>
      _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends ConsumerState<RaiseComplaintScreen> {
  final _description = TextEditingController();
  String _category = 'electrical';
  bool _busy = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authControllerProvider).user;
    final propId = user?.propertyId ?? '';
    if (user == null || _description.text.trim().isEmpty || propId.isEmpty) {
      _snack('Enter a description');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createComplaint(Complaint(
            id: '',
            propertyId: propId,
            inmateId: user.id,
            category: _category,
            description: _description.text.trim(),
          ));
      ref.invalidate(inmateComplaintsProvider(user.id));
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Complaint submitted')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack('Could not submit: $e');
      }
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raise a complaint'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('What needs fixing?', style: textTheme.displayLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in kComplaintCategories)
                      _categoryChip(c, _category == c,
                          () => setState(() => _category = c)),
                  ],
                ),
                const SizedBox(height: 20),
                GlassTextField(
                  controller: _description,
                  label: 'Describe the issue',
                  icon: Icons.report_problem_outlined,
                ),
                const SizedBox(height: 24),
                GlassButton(
                  label: 'Submit complaint',
                  loading: _busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? primary.withValues(alpha: 0.18)
              : (isDark ? AppColors.glassDark : AppColors.glassLight),
          border: Border.all(color: selected ? primary : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? primary : muted)),
      ),
    );
  }
}

Color complaintStatusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.accent;
    case 'in_progress':
      return AppColors.warning;
    default:
      return AppColors.danger;
  }
}
