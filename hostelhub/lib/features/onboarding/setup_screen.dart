import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import 'hostel_providers.dart';

/// Property types the owner can onboard. Mess/polls is relevant to hostels/PGs.
const _propertyTypes = <(String, String)>[
  ('hostel', 'Hostel'),
  ('pg', 'PG'),
  ('house', 'House (rent)'),
  ('office', 'Office space'),
];

/// Owner onboarding wizard: step 1 hostel details, step 2 rooms.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _step = 0;
  String? _propertyId;
  String _type = 'hostel';
  bool _busy = false;

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _roomNo = TextEditingController();
  final _capacity = TextEditingController();
  final _rentAmount = TextEditingController();
  final List<Room> _rooms = [];

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _roomNo.dispose();
    _capacity.dispose();
    _rentAmount.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_propertyId != null) {
      setState(() => _step = 1);
      return;
    }
    final user = ref.read(authControllerProvider).user;
    if (user == null || _name.text.trim().isEmpty) {
      _snack('Enter a hostel name');
      return;
    }
    setState(() => _busy = true);
    try {
      final prop = await ref.read(backendProvider).properties.createProperty(
            Property(
              id: '',
              ownerId: user.id,
              name: _name.text.trim(),
              address: _address.text.trim(),
              type: _type,
              rentAmount: int.tryParse(_rentAmount.text.trim()) ?? 0,
            ),
          );
      _propertyId = prop.id;
      ref.invalidate(propertiesProvider);
      ref.invalidate(currentPropertyProvider);
      setState(() => _busy = false);
      // Houses & offices have no rooms — rent is per property, so finish here.
      if (_type == 'hostel' || _type == 'pg') {
        setState(() => _step = 1);
      } else {
        _finish();
      }
    } catch (e) {
      setState(() => _busy = false);
      _snack('Could not create hostel: $e');
    }
  }

  Future<void> _addRoom() async {
    final id = _propertyId;
    final no = _roomNo.text.trim();
    if (id == null || no.isEmpty) return;
    final capacity = int.tryParse(_capacity.text.trim()) ?? 1;
    setState(() => _busy = true);
    try {
      final room = await ref.read(backendProvider).rooms.createRoom(
            Room(id: '', propertyId: id, roomNo: no, capacity: capacity),
          );
      ref.invalidate(roomsProvider(id));
      setState(() {
        _rooms.add(room);
        _roomNo.clear();
        _capacity.clear();
        _busy = false;
      });
    } catch (e) {
      setState(() => _busy = false);
      _snack('Could not add room: $e');
    }
  }

  void _finish() {
    if (_propertyId != null) {
      ref.read(selectedPropertyIdProvider.notifier).select(_propertyId!);
    }
    ref.invalidate(propertiesProvider);
    ref.invalidate(currentPropertyProvider);
    context.go('/home');
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Widget _typeChip(String value, String label, bool selected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : (isDark ? AppColors.glassDark : AppColors.glassLight),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : muted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_step == 0 ? 'Set up your property' : 'Add rooms'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: _step == 0 ? _stepProperty(textTheme) : _stepRooms(textTheme),
          ),
        ),
      ),
    );
  }

  Widget _stepProperty(TextTheme textTheme) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tell us about your hostel', style: textTheme.displayLarge),
          const SizedBox(height: 6),
          Text('You can add rooms, rent slabs and mess charges next.',
              style: textTheme.bodyMedium),
          const SizedBox(height: 28),
          GlassTextField(
              controller: _name,
              label: 'Property name',
              icon: Icons.apartment_rounded),
          const SizedBox(height: 14),
          GlassTextField(
              controller: _address,
              label: 'Address (optional)',
              icon: Icons.location_on_outlined),
          const SizedBox(height: 20),
          Text('Property type', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _propertyTypes)
                _typeChip(t.$1, t.$2, _type == t.$1),
            ],
          ),
          if (_type == 'house' || _type == 'office') ...[
            const SizedBox(height: 20),
            Text('Monthly rent', style: textTheme.titleMedium),
            const SizedBox(height: 10),
            GlassTextField(
                controller: _rentAmount,
                label: 'Rent (₹/mo)',
                icon: Icons.currency_rupee,
                keyboardType: TextInputType.number),
          ],
          const SizedBox(height: 40),
          GlassButton(label: 'Next', loading: _busy, onPressed: _next),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _stepRooms(TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Add your rooms', style: textTheme.displayLarge),
        const SizedBox(height: 6),
        Text('Room number + bed capacity. Add as many as you need.',
            style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GlassTextField(
                  controller: _roomNo,
                  label: 'Room no.',
                  icon: Icons.door_sliding_outlined),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassTextField(
                  controller: _capacity,
                  label: 'Beds',
                  icon: Icons.bed_outlined,
                  keyboardType: TextInputType.number),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassButton(
            label: 'Add room',
            icon: Icons.add_rounded,
            loading: _busy,
            onPressed: _addRoom),
        const SizedBox(height: 20),
        Expanded(
          child: _rooms.isEmpty
              ? Center(
                  child: Text('No rooms yet — add your first room above.',
                      style: textTheme.bodyMedium))
              : ListView.builder(
                  itemCount: _rooms.length,
                  itemBuilder: (_, i) {
                    final r = _rooms[i];
                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Room ${r.roomNo}',
                              style: textTheme.titleMedium),
                          Text('${r.capacity} beds',
                              style: textTheme.bodyMedium),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 12),
        GlassButton(label: 'Finish setup', onPressed: _finish),
        const SizedBox(height: 16),
      ],
    );
  }
}
