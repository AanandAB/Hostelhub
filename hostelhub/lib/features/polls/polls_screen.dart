import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/poll.dart';
import '../../data/models/poll_response.dart';
import '../../data/models/property.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';
import 'poll_providers.dart';

/// Owner "Polls" tab: create, list with live headcount, nudge non-responders.
class PollsScreen extends ConsumerStatefulWidget {
  const PollsScreen({super.key});

  @override
  ConsumerState<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends ConsumerState<PollsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final propAsync = ref.watch(currentPropertyProvider);

    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: propAsync.when(
          data: (prop) {
            if (prop == null) {
              return Center(
                child: Text('Set up your hostel first.',
                    style: textTheme.bodyMedium),
              );
            }
            return _content(prop);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
              child: Text('Error loading hostel', style: textTheme.bodyMedium)),
        ),
      ),
    );
  }

  Widget _content(Property prop) {
    final textTheme = Theme.of(context).textTheme;
    final polls =
        ref.watch(pollsProvider(prop.id)).value ?? const <Poll>[];
    final inmates = ref.watch(inmatesProvider(prop.id)).value ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text('Mess polls', style: textTheme.displayLarge),
        const SizedBox(height: 16),
        GlassButton(
          label: 'New poll',
          icon: Icons.add_rounded,
          onPressed: () => _showCreatePollDialog(prop.id),
        ),
        const SizedBox(height: 24),
        if (polls.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Text(
                'No polls yet — create your first mess poll.',
                style: textTheme.bodyMedium,
              ),
            ),
          )
        else
          for (final p in polls.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PollCard(poll: p, totalInmates: inmates.length),
            ),
      ],
    );
  }

  void _showCreatePollDialog(String propertyId) {
    showDialog(
      context: context,
      builder: (_) => _CreatePollDialog(propertyId: propertyId),
    );
  }
}

/// Per-poll card: option counts + not-responded count + nudge button.
class _PollCard extends ConsumerWidget {
  final Poll poll;
  final int totalInmates;
  const _PollCard({required this.poll, required this.totalInmates});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(pollResponsesProvider(poll.id)).value ??
        const <PollResponse>[];
    final textTheme = Theme.of(context).textTheme;
    final counts = <String, int>{};
    for (final r in responses) {
      counts[r.response] = (counts[r.response] ?? 0) + 1;
    }
    final pending = (totalInmates - responses.length).clamp(0, 1 << 30);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${mealLabel(poll.mealType)} · ${friendlyDate(poll.forDate)}',
                  style: textTheme.titleMedium,
                ),
              ),
              if (poll.recurring)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('recurring', style: textTheme.bodySmall),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final opt in poll.options)
                _countChip(context, '$opt: ${counts[opt] ?? 0}'),
              _countChip(context, 'No response: $pending'),
            ],
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: pending > 0 ? 'Nudge $pending non-responders' : 'All responded ✓',
            icon: Icons.notifications_active_rounded,
            onPressed: pending > 0
                ? () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Nudge sent to $pending inmates')));
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _countChip(BuildContext context, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
        border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 13, color: muted)),
    );
  }
}

/// New-poll dialog: meal type + recurring (sends for tomorrow).
class _CreatePollDialog extends ConsumerStatefulWidget {
  final String propertyId;
  const _CreatePollDialog({required this.propertyId});

  @override
  ConsumerState<_CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends ConsumerState<_CreatePollDialog> {
  String _mealType = 'dinner';
  bool _recurring = false;
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final forDate = tomorrow.toIso8601String().substring(0, 10);
    try {
      await ref.read(backendProvider).polls.createPoll(Poll(
            id: '',
            propertyId: widget.propertyId,
            mealType: _mealType,
            forDate: forDate,
            recurring: _recurring,
            options: const ['Yes', 'No'],
          ));
      ref.invalidate(pollsProvider(widget.propertyId));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not create poll: $e')));
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
            Text('New mess poll', style: textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('For tomorrow · one-tap Yes/No', style: textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('Meal', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final m in const ['breakfast', 'lunch', 'dinner'])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _mealChip(mealLabel(m), _mealType == m,
                          () => setState(() => _mealType = m)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text('Repeat daily', style: textTheme.bodyLarge)),
                Switch(
                  value: _recurring,
                  onChanged: (v) => setState(() => _recurring = v),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassButton(
                label: 'Create poll', loading: _busy, onPressed: _create),
          ],
        ),
      ),
    );
  }

  Widget _mealChip(String label, bool selected, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: selected
              ? primary.withValues(alpha: 0.18)
              : (isDark ? AppColors.glassDark : AppColors.glassLight),
          border: Border.all(
              color: selected
                  ? primary
                  : Colors.white.withValues(alpha: isDark ? 0.12 : 0.5)),
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

/// Inmate "today's poll" card: one-tap Yes/No response.
class InmatePollCard extends ConsumerWidget {
  final Poll poll;
  final String inmateId;
  const InmatePollCard({super.key, required this.poll, required this.inmateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(pollResponsesProvider(poll.id)).value ??
        const <PollResponse>[];
    final mine = responses.where((r) => r.inmateId == inmateId).firstOrNull;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accentDark : AppColors.accent;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 20, color: accent),
              const SizedBox(width: 8),
              Expanded(
                  child: Text("Today's mess", style: textTheme.bodySmall)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${mealLabel(poll.mealType)} · ${friendlyDate(poll.forDate)}',
              style: textTheme.titleLarge),
          const SizedBox(height: 4),
          Text('Are you eating?', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          if (mine != null)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: accent),
                const SizedBox(width: 8),
                Text('You said ${mine.response}', style: textTheme.bodyLarge),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                    child: _respondButton(
                        'Yes', accent, () => _respond(ref, 'Yes'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _respondButton(
                        'No', accent.withValues(alpha: 0.8),
                        () => _respond(ref, 'No'))),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _respond(WidgetRef ref, String response) async {
    HapticFeedback.mediumImpact();
    await ref.read(backendProvider).polls.respond(PollResponse(
          id: '',
          pollId: poll.id,
          inmateId: inmateId,
          response: response,
        ));
    ref.invalidate(pollResponsesProvider(poll.id));
  }

  Widget _respondButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)]),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}

String mealLabel(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    default:
      return 'Dinner';
  }
}

String friendlyDate(String iso) {
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  if (d.year == tomorrow.year &&
      d.month == tomorrow.month &&
      d.day == tomorrow.day) {
    return 'tomorrow';
  }
  return '${d.day}/${d.month}';
}
