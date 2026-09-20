import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/inmate.dart';
import '../../data/models/leave_record.dart';
import '../../data/models/visitor.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

/// Owner: visitor log with check-in/check-out.
class VisitorsScreen extends ConsumerStatefulWidget {
  const VisitorsScreen({super.key});

  @override
  ConsumerState<VisitorsScreen> createState() => _VisitorsScreenState();
}

class _VisitorsScreenState extends ConsumerState<VisitorsScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _purpose = TextEditingController();
  String? _selectedInmateId;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _purpose.dispose();
    super.dispose();
  }

  Future<void> _logVisitor(String propertyId) async {
    if (_name.text.trim().isEmpty) return;
    String visitingName = '';
    if (_selectedInmateId != null) {
      final inmates =
          ref.read(inmatesProvider(propertyId)).value ?? const <Inmate>[];
      for (final i in inmates) {
        if (i.id == _selectedInmateId) {
          visitingName = i.name;
          break;
        }
      }
    }
    try {
      await ref.read(backendProvider).ops.createVisitor(Visitor(
            id: '',
            propertyId: propertyId,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            purpose: _purpose.text.trim(),
            visitingInmateName: visitingName,
          ));
      ref.invalidate(visitorsProvider(propertyId));
      _name.clear();
      _phone.clear();
      _purpose.clear();
      _selectedInmateId = null;
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _snack('Could not log visitor: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitors'),
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
                : _content(prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(String propertyId, TextTheme textTheme) {
    final visitors =
        ref.watch(visitorsProvider(propertyId)).value ?? const <Visitor>[];
    final inside = visitors.where((v) => v.isInside).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
                child:
                    Text('$inside inside now', style: textTheme.titleLarge)),
            GlassButton(
              label: 'Log visitor',
              icon: Icons.person_add_alt_rounded,
              onPressed: () => _showLogDialog(propertyId),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (visitors.isEmpty)
          Center(child: Text('No visitors yet.', style: textTheme.bodyMedium))
        else
          for (final v in visitors.reversed) _visitorCard(v, propertyId),
      ],
    );
  }

  void _showLogDialog(String propertyId) {
    final inmates =
        ref.read(inmatesProvider(propertyId)).value ?? const <Inmate>[];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Log visitor', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                GlassTextField(
                    controller: _name,
                    label: 'Visitor name',
                    icon: Icons.person_outline),
                const SizedBox(height: 12),
                GlassTextField(
                    controller: _phone,
                    label: 'Phone',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedInmateId ?? '',
                  items: [
                    const DropdownMenuItem(
                        value: '', child: Text('General visitor')),
                    for (final i in inmates)
                      DropdownMenuItem(value: i.id, child: Text(i.name)),
                  ],
                  onChanged: (v) => setDialogState(() =>
                      _selectedInmateId =
                          (v == null || v.isEmpty) ? null : v),
                  decoration:
                      const InputDecoration(labelText: 'Visiting (inmate)'),
                ),
                const SizedBox(height: 12),
                GlassTextField(
                    controller: _purpose,
                    label: 'Purpose',
                    icon: Icons.info_outline),
                const SizedBox(height: 16),
                GlassButton(
                    label: 'Check in',
                    onPressed: () => _logVisitor(propertyId)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _visitorCard(Visitor v, String propertyId) {
    final textTheme = Theme.of(context).textTheme;
    final color = v.isInside ? AppColors.accent : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.16),
              ),
              child: Icon(Icons.person_rounded, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.name, style: textTheme.titleMedium),
                  Text(
                    v.visitingInmateName.isEmpty
                        ? '—'
                        : 'Visiting ${v.visitingInmateName}',
                    style: textTheme.bodySmall,
                  ),
                  Text(
                    v.isInside
                        ? 'Inside since ${_time(v.inTime)}'
                        : 'Left at ${_time(v.outTime)}',
                    style: textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (v.isInside)
              TextButton(
                onPressed: () async {
                  await ref.read(backendProvider).ops.checkOutVisitor(v.id);
                  ref.invalidate(visitorsProvider(propertyId));
                },
                child: const Text('Check out'),
              ),
          ],
        ),
      ),
    );
  }

  String _time(String? iso) => iso == null ? '—' : iso.substring(11, 16);
}

/// Owner: who's currently on leave.
class LeaveScreen extends ConsumerWidget {
  const LeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave'),
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
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, String propertyId,
      TextTheme textTheme) {
    final records =
        ref.watch(leaveProvider(propertyId)).value ?? const <LeaveRecord>[];
    if (records.isEmpty) {
      return Center(child: Text('No one on leave.', style: textTheme.bodyMedium));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        for (final r in records)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.directions_walk_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.inmateName, style: textTheme.titleMedium),
                        Text('${r.startDate} → ${r.endDate}',
                            style: textTheme.bodySmall),
                        if (r.reason.isNotEmpty)
                          Text(r.reason, style: textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text('on leave',
                      style: const TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Inmate: mark going home / on leave.
class MarkLeaveScreen extends ConsumerStatefulWidget {
  const MarkLeaveScreen({super.key});

  @override
  ConsumerState<MarkLeaveScreen> createState() => _MarkLeaveScreenState();
}

class _MarkLeaveScreenState extends ConsumerState<MarkLeaveScreen> {
  final _start = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));
  final _end = TextEditingController(
      text: DateTime.now()
          .add(const Duration(days: 2))
          .toIso8601String()
          .substring(0, 10));
  final _reason = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _start.dispose();
    _end.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createLeave(LeaveRecord(
            id: '',
            propertyId: user.propertyId ?? '',
            inmateId: user.id,
            startDate: _start.text.trim(),
            endDate: _end.text.trim(),
            reason: _reason.text.trim(),
          ));
      ref.invalidate(inmateLeaveProvider(user.id));
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Leave marked')));
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not mark leave: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark leave'),
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
                Text('Going home?', style: textTheme.displayLarge),
                const SizedBox(height: 16),
                GlassTextField(
                    controller: _start,
                    label: 'Start date (YYYY-MM-DD)',
                    icon: Icons.event_rounded),
                const SizedBox(height: 12),
                GlassTextField(
                    controller: _end,
                    label: 'Return date (YYYY-MM-DD)',
                    icon: Icons.event_available_rounded),
                const SizedBox(height: 12),
                GlassTextField(
                    controller: _reason,
                    label: 'Reason (optional)',
                    icon: Icons.notes_outlined),
                const SizedBox(height: 24),
                GlassButton(
                    label: 'Mark leave',
                    loading: _busy,
                    onPressed: _submit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
