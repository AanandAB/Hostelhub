import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/notice.dart';
import '../../presentation/widgets/glass.dart';
import '../../services/sounds/sound_service.dart';
import '../auth/auth_controller.dart';
import 'ops_providers.dart';

const kNoticeCategories = ['general', 'mess', 'maintenance', 'emergency'];

/// Inmate "Notices" tab: read the hostel notice board (pinned first).
class NoticesScreen extends ConsumerWidget {
  const NoticesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final propertyId = user?.propertyId ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final notices =
        ref.watch(noticesProvider(propertyId)).value ?? const <Notice>[];

    final sorted = [...notices]..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return (b.createdAt ?? '').compareTo(a.createdAt ?? '');
      });

    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: sorted.isEmpty
            ? Center(child: Text('No notices yet.', style: textTheme.bodyMedium))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                children: [
                  Text('Notices', style: textTheme.displayLarge),
                  const SizedBox(height: 16),
                  for (final n in sorted) _NoticeCard(notice: n),
                ],
              ),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  const _NoticeCard({required this.notice});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (notice.pinned) ...[
                  Icon(Icons.push_pin_rounded, size: 16, color: primary),
                  const SizedBox(width: 4),
                ],
                Expanded(
                    child: Text(notice.title, style: textTheme.titleMedium)),
                _categoryTag(notice.category),
              ],
            ),
            if (notice.body.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(notice.body, style: textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryTag(String category) {
    final color =
        category == 'emergency' ? AppColors.danger : AppColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(category, style: TextStyle(fontSize: 11, color: color)),
    );
  }
}

/// Owner: compose a notice (opened from the More hub).
class PostNoticeDialog extends ConsumerStatefulWidget {
  final String propertyId;
  const PostNoticeDialog({super.key, required this.propertyId});

  @override
  ConsumerState<PostNoticeDialog> createState() => _PostNoticeDialogState();
}

class _PostNoticeDialogState extends ConsumerState<PostNoticeDialog> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _category = 'general';
  bool _pinned = false;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createNotice(Notice(
            id: '',
            propertyId: widget.propertyId,
            title: _title.text.trim(),
            body: _body.text.trim(),
            category: _category,
            pinned: _pinned,
          ));
      ref.invalidate(noticesProvider(widget.propertyId));
      SoundService.playNotice();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not post: $e')));
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
            Text('Post notice', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            GlassTextField(
                controller: _title,
                label: 'Title',
                icon: Icons.campaign_outlined),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _body,
                label: 'Body (optional)',
                icon: Icons.notes_outlined),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                for (final c in kNoticeCategories)
                  _chip(c, _category == c, () => setState(() => _category = c)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('Pin to top', style: textTheme.bodyLarge)),
                Switch(
                    value: _pinned,
                    onChanged: (v) => setState(() => _pinned = v)),
              ],
            ),
            const SizedBox(height: 16),
            GlassButton(label: 'Post', loading: _busy, onPressed: _post),
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
