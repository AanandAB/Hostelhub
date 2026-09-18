import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/pricing.dart';
import '../../data/models/user.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';

final pricingProvider = FutureProvider<PricingConfig>(
    (ref) => ref.watch(backendProvider).admin.getPricing());

final adminOwnersProvider = FutureProvider<List<User>>(
    (ref) => ref.watch(backendProvider).admin.listOwners());

/// Super-admin panel: set subscription rates globally or per client.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  final _monthly = TextEditingController();
  final _yearly = TextEditingController();
  final _extra = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _monthly.dispose();
    _yearly.dispose();
    _extra.dispose();
    super.dispose();
  }

  void _fill(Pricing p) {
    if (_filled) return;
    _filled = true;
    _monthly.text = '${p.monthly}';
    _yearly.text = '${p.yearly}';
    _extra.text = '${p.extraProperty}';
  }

  Future<void> _saveGlobal() async {
    final p = Pricing(
      monthly: int.tryParse(_monthly.text.trim()) ?? 0,
      yearly: int.tryParse(_yearly.text.trim()) ?? 0,
      extraProperty: int.tryParse(_extra.text.trim()) ?? 0,
    );
    await ref.read(backendProvider).admin.updatePricing(p);
    ref.invalidate(pricingProvider);
    if (mounted) _snack('Global rates saved');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final pricing = ref.watch(pricingProvider).value;
    final owners = ref.watch(adminOwnersProvider).value ?? const <User>[];
    if (pricing != null) _fill(pricing.global);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin panel'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text('Admin panel', style: textTheme.displayLarge),
              const SizedBox(height: 4),
              Text('Subscription rates (₹) — applies to all clients unless overridden.',
                  style: textTheme.bodyMedium),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Global rates', style: textTheme.titleLarge),
                    const SizedBox(height: 12),
                    GlassTextField(
                        controller: _monthly,
                        label: 'Monthly (₹/mo)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    GlassTextField(
                        controller: _yearly,
                        label: 'Yearly (₹/yr)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    GlassTextField(
                        controller: _extra,
                        label: 'Extra property (₹/mo)',
                        icon: Icons.currency_rupee,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    GlassButton(label: 'Save global rates', onPressed: _saveGlobal),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Clients', style: textTheme.titleLarge),
              const SizedBox(height: 10),
              if (owners.isEmpty)
                Text('No owner accounts yet.', style: textTheme.bodySmall)
              else
                for (final o in owners)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(o.name, style: textTheme.titleMedium),
                                Text(
                                    '@${o.username} · ${_ratesText(pricing?.effectiveFor(o.id))}',
                                    style: textTheme.bodySmall),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _editOverride(o, pricing),
                            child: const Text('Override'),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratesText(Pricing? p) => p == null
      ? '—'
      : '₹${p.monthly}/mo · ₹${p.yearly}/yr · +₹${p.extraProperty}';

  void _editOverride(User owner, PricingConfig? pricing) {
    final effective = pricing?.effectiveFor(owner.id);
    final hasOverride = pricing?.overrides.containsKey(owner.id) ?? false;
    final m = TextEditingController(text: '${effective?.monthly ?? 0}');
    final y = TextEditingController(text: '${effective?.yearly ?? 0}');
    final e = TextEditingController(
        text: '${effective?.extraProperty ?? 0}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text('Override for ${owner.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: m,
                decoration: const InputDecoration(labelText: 'Monthly (₹/mo)'),
                keyboardType: TextInputType.number),
            TextField(
                controller: y,
                decoration: const InputDecoration(labelText: 'Yearly (₹/yr)'),
                keyboardType: TextInputType.number),
            TextField(
                controller: e,
                decoration:
                    const InputDecoration(labelText: 'Extra property (₹/mo)'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          if (hasOverride)
            TextButton(
              onPressed: () async {
                await ref
                    .read(backendProvider)
                    .admin
                    .setOverride(owner.id, null);
                ref.invalidate(pricingProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Clear override'),
            ),
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              await ref.read(backendProvider).admin.setOverride(
                  owner.id,
                  Pricing(
                    monthly: int.tryParse(m.text) ?? 0,
                    yearly: int.tryParse(y.text) ?? 0,
                    extraProperty: int.tryParse(e.text) ?? 0,
                  ));
              ref.invalidate(pricingProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
