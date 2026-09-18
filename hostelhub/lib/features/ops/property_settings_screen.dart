import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/property.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';

/// Owner controls which features a property exposes. Inmates only see the
/// features that are switched on here.
class PropertySettingsScreen extends ConsumerWidget {
  const PropertySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property settings'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(
                    child: Text('Set up your property first.',
                        style: textTheme.bodyMedium))
                : _content(context, ref, prop),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Property prop) {
    final textTheme = Theme.of(context).textTheme;
    final messEnabled = prop.featureEnabled('mess');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(prop.name, style: textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Type: ${_typeLabel(prop.type)}',
                  style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.16),
                ),
                child: const Icon(Icons.restaurant_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mess & polls', style: textTheme.titleMedium),
                    Text('Inmates can see food polls and respond',
                        style: textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: messEnabled,
                onChanged: (v) => _toggle(context, ref, prop.id, v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Only inmates can see the features you turn on.',
            style: textTheme.bodySmall),
      ],
    );
  }

  Future<void> _toggle(
      BuildContext context, WidgetRef ref, String id, bool value) async {
    await ref
        .read(backendProvider)
        .properties
        .updateProperty(id, features: {'mess': value});
    ref.invalidate(propertiesProvider);
    ref.invalidate(currentPropertyProvider);
    ref.invalidate(propertyProvider(id));
  }

  String _typeLabel(String t) => switch (t) {
        'pg' => 'PG',
        'house' => 'House (rent)',
        'office' => 'Office space',
        _ => 'Hostel',
      };
}
