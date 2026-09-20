import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../presentation/widgets/glass.dart';
import '../../services/sounds/sound_service.dart';
import '../onboarding/hostel_providers.dart';
import 'ops_providers.dart';

/// Owner: SOS alerts, with acknowledge. Plays a high-alert sound when an
/// unacknowledged alert is present.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  bool _alerted = false;

  @override
  Widget build(BuildContext context) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS alerts'),
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
    final alerts = ref.watch(sosProvider(propertyId)).value ?? const [];
    final hasUnacknowledged = alerts.any((a) => !a.acknowledged);
    if (hasUnacknowledged && !_alerted) {
      _alerted = true;
      SoundService.playSosAlert();
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        if (alerts.isEmpty)
          Center(child: Text('No SOS alerts.', style: textTheme.bodyMedium))
        else
          for (final a in alerts.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                tint: a.acknowledged
                    ? null
                    : AppColors.danger.withValues(alpha: 0.14),
                child: Row(
                  children: [
                    const Icon(Icons.sos_rounded,
                        color: AppColors.danger, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.inmateName, style: textTheme.titleMedium),
                          Text(
                            a.triggeredAt?.substring(0, 16) ?? '',
                            style: textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (a.acknowledged)
                      const Text('Acknowledged',
                          style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 12))
                    else
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(backendProvider)
                              .ops
                              .acknowledgeSos(a.id);
                          ref.invalidate(sosProvider(propertyId));
                        },
                        child: const Text('Acknowledge'),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
