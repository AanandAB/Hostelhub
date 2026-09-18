import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';

/// Owner form to onboard an inmate: assign room/bed + rent, auto-generate login.
class AddInmateScreen extends ConsumerStatefulWidget {
  const AddInmateScreen({super.key});

  @override
  ConsumerState<AddInmateScreen> createState() => _AddInmateScreenState();
}

class _AddInmateScreenState extends ConsumerState<AddInmateScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _bedNo = TextEditingController(text: '1');
  final _rent = TextEditingController();
  final _dueDay = TextEditingController(text: '1');
  String? _roomId;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bedNo.dispose();
    _rent.dispose();
    _dueDay.dispose();
    super.dispose();
  }

  Future<void> _submit(String propertyId) async {
    if (_name.text.trim().isEmpty || _roomId == null) {
      _snack('Enter a name and pick a room');
      return;
    }
    final rent = int.tryParse(_rent.text.trim()) ?? 0;
    final bed = int.tryParse(_bedNo.text.trim()) ?? 1;
    final due = int.tryParse(_dueDay.text.trim()) ?? 1;
    setState(() => _busy = true);
    try {
      final result = await ref.read(backendProvider).inmates.createInmate(
            propertyId: propertyId,
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            roomId: _roomId!,
            bedNo: bed,
            rentAmount: rent,
            dueDay: due,
            joinDate: DateTime.now().toIso8601String().substring(0, 10),
          );
      ref.invalidate(inmatesProvider(propertyId));
      if (!mounted) return;
      setState(() => _busy = false);
      await _showCredentials(result.inmate.username, result.password);
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _snack('Could not add inmate: $e');
    }
  }

  Future<void> _showCredentials(String username, String password) {
    return showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded,
                    size: 40, color: AppColors.accent),
                const SizedBox(height: 12),
                Text('Inmate added',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Share these login details with the inmate:',
                    style: Theme.of(ctx).textTheme.bodyMedium),
                const SizedBox(height: 16),
                _credRow(ctx, 'Username', username),
                const SizedBox(height: 8),
                _credRow(ctx, 'Password', password),
                const SizedBox(height: 20),
                GlassButton(
                  label: 'Copy credentials',
                  icon: Icons.copy_rounded,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                        text: 'Username: $username\nPassword: $password'));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Copied')));
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _credRow(BuildContext ctx, String label, String value) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.glassDark : AppColors.glassLight,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: muted)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final propertyAsync = ref.watch(currentPropertyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add inmate'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propertyAsync.when(
            data: (prop) {
              if (prop == null) {
                return Center(
                    child:
                        Text('Set up your hostel first.', style: textTheme.bodyMedium));
              }
              return _form(prop.id, textTheme);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) =>
                Center(child: Text('Error loading hostel', style: textTheme.bodyMedium)),
          ),
        ),
      ),
    );
  }

  Widget _form(String propertyId, TextTheme textTheme) {
    final roomsAsync = ref.watch(roomsProvider(propertyId));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassTextField(
              controller: _name, label: 'Full name', icon: Icons.badge_outlined),
          const SizedBox(height: 14),
          GlassTextField(
              controller: _phone,
              label: 'Phone',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 20),
          Text('Room', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          roomsAsync.when(
            data: (rooms) => rooms.isEmpty
                ? Text('No rooms yet — add rooms first.',
                    style: textTheme.bodySmall)
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in rooms)
                        _roomChip(r.id, 'Room ${r.roomNo} (${r.capacity})',
                            r.id == _roomId),
                    ],
                  ),
            loading: () => const SizedBox(
                height: 20,
                child: Center(child: CircularProgressIndicator())),
            error: (_, _) => Text('Error loading rooms', style: textTheme.bodySmall),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GlassTextField(
                    controller: _bedNo,
                    label: 'Bed no.',
                    icon: Icons.bed_outlined,
                    keyboardType: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassTextField(
                    controller: _rent,
                    label: 'Rent (₹/mo)',
                    icon: Icons.currency_rupee,
                    keyboardType: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassTextField(
              controller: _dueDay,
              label: 'Due day (1-31)',
              icon: Icons.event_rounded,
              keyboardType: TextInputType.number),
          const SizedBox(height: 28),
          GlassButton(
              label: 'Add inmate',
              loading: _busy,
              onPressed: () => _submit(propertyId)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _roomChip(String id, String label, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: () => setState(() => _roomId = id),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        tint: selected ? primary.withValues(alpha: 0.18) : null,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? primary : muted)),
      ),
    );
  }
}
