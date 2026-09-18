import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/rating.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

/// Owner: aggregate + individual stay ratings.
class RatingsScreen extends ConsumerWidget {
  const RatingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings'),
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
                : _content(ref, prop.id, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(WidgetRef ref, String propertyId, TextTheme textTheme) {
    final ratings =
        ref.watch(ratingsProvider(propertyId)).value ?? const <Rating>[];
    final avg = ratings.isEmpty
        ? 0.0
        : ratings.map((r) => r.stars).reduce((a, b) => a + b) /
            ratings.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        GlassCard(
          child: Row(
            children: [
              Text(avg.toStringAsFixed(1), style: textTheme.displayLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stars(avg.round(), 22),
                    const SizedBox(height: 4),
                    Text('${ratings.length} rating(s)',
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (ratings.isEmpty)
          Center(child: Text('No ratings yet.', style: textTheme.bodyMedium))
        else
          for (final r in ratings.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child:
                                Text(r.inmateName, style: textTheme.titleMedium)),
                        _stars(r.stars, 16),
                      ],
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }

  Widget _stars(int count, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < count ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: AppColors.warning,
          ),
      ],
    );
  }
}

/// Inmate: rate their stay (opened from the More hub).
class RateStayDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final String inmateId;
  const RateStayDialog(
      {super.key, required this.propertyId, required this.inmateId});

  @override
  ConsumerState<RateStayDialog> createState() => _RateStayDialogState();
}

class _RateStayDialogState extends ConsumerState<RateStayDialog> {
  final _comment = TextEditingController();
  int _stars = 5;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      await ref.read(backendProvider).ops.createRating(Rating(
            id: '',
            propertyId: widget.propertyId,
            inmateId: widget.inmateId,
            stars: _stars,
            comment: _comment.text.trim(),
          ));
      ref.invalidate(ratingsProvider(widget.propertyId));
      if (mounted) {
        setState(() => _busy = false);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thanks for rating!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not submit: $e')));
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
            Text('Rate your stay', style: textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  GestureDetector(
                    onTap: () => setState(() => _stars = i),
                    child: Icon(
                      i <= _stars
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 36,
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GlassTextField(
                controller: _comment,
                label: 'Comment (optional)',
                icon: Icons.notes_outlined),
            const SizedBox(height: 16),
            GlassButton(label: 'Submit', loading: _busy, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
