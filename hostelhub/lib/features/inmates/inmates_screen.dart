import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';

/// Owner "Inmates" tab: room occupancy + inmate list + add-inmate/add-room.
class InmatesScreen extends ConsumerStatefulWidget {
  const InmatesScreen({super.key});

  @override
  ConsumerState<InmatesScreen> createState() => _InmatesScreenState();
}

class _InmatesScreenState extends ConsumerState<InmatesScreen> {
  final _roomNo = TextEditingController();
  final _capacity = TextEditingController(text: '2');

  @override
  void dispose() {
    _roomNo.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _addRoom(Property prop) async {
    final no = _roomNo.text.trim();
    if (no.isEmpty) return;
    final cap = int.tryParse(_capacity.text.trim()) ?? 2;
    try {
      await ref.read(backendProvider).rooms.createRoom(
            Room(id: '', propertyId: prop.id, roomNo: no, capacity: cap),
          );
      ref.invalidate(roomsProvider(prop.id));
      _roomNo.clear();
      _capacity.text = '2';
      if (mounted) Navigator.of(context).pop(); // close dialog
    } catch (e) {
      _snack('Could not add room: $e');
    }
  }

  void _showAddRoomDialog(Property prop) {
    showDialog(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add room', style: textTheme.titleLarge),
                const SizedBox(height: 16),
                GlassTextField(
                    controller: _roomNo,
                    label: 'Room no.',
                    icon: Icons.door_sliding_outlined),
                const SizedBox(height: 12),
                GlassTextField(
                    controller: _capacity,
                    label: 'Beds',
                    icon: Icons.bed_outlined,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                GlassButton(
                    label: 'Add room', onPressed: () => _addRoom(prop)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

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
              final muted = isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apartment_rounded, size: 40, color: muted),
                        const SizedBox(height: 12),
                        Text('No hostel yet', style: textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(
                          'Set up your hostel to start adding rooms and inmates.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        GlassButton(
                          label: 'Set up your hostel',
                          onPressed: () => context.go('/setup'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return _content(prop, textTheme);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
              child: Text('Error loading hostel', style: textTheme.bodyMedium)),
        ),
      ),
    );
  }

  Widget _content(Property prop, TextTheme textTheme) {
    final roomsAsync = ref.watch(roomsProvider(prop.id));
    final inmatesAsync = ref.watch(inmatesProvider(prop.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text(prop.name, style: textTheme.displayLarge),
        if (prop.address != null && prop.address!.isNotEmpty)
          Text(prop.address!, style: textTheme.bodyMedium),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GlassButton(
                label: 'Add inmate',
                icon: Icons.person_add_alt_rounded,
                onPressed: () => context.go('/inmates/new'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassButton(
                label: 'Add room',
                icon: Icons.add_rounded,
                color: primary.withValues(alpha: 0.8),
                onPressed: () => _showAddRoomDialog(prop),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Rooms', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        roomsAsync.when(
          data: (rooms) {
            final inmates = inmatesAsync.value ?? const [];
            if (rooms.isEmpty) {
              return Text('No rooms yet — add your first room.',
                  style: textTheme.bodyMedium);
            }
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final r in rooms)
                  _roomCard(r, inmates.where((i) => i.roomId == r.id).length,
                      primary),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              Text('Error loading rooms', style: textTheme.bodyMedium),
        ),
        const SizedBox(height: 24),
        Text('Inmates', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        inmatesAsync.when(
          data: (inmates) => inmates.isEmpty
              ? Text('No inmates yet — add your first inmate.',
                  style: textTheme.bodyMedium)
              : Column(
                  children: [
                    for (final i in inmates)
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primary.withValues(alpha: 0.16),
                              ),
                              child:
                                  Icon(Icons.person_rounded, size: 20, color: primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(i.name, style: textTheme.titleMedium),
                                  Text('Room ${i.roomNo} · Bed ${i.bedNo}',
                                      style: textTheme.bodySmall),
                                ],
                              ),
                            ),
                            Text('₹${i.rentAmount}', style: textTheme.titleMedium),
                          ],
                        ),
                      ),
                  ],
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              Text('Error loading inmates', style: textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _roomCard(Room room, int occupied, Color primary) {
    final textTheme = Theme.of(context).textTheme;
    final pct =
        room.capacity == 0 ? 0.0 : (occupied / room.capacity).clamp(0.0, 1.0);
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 110,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Room ${room.roomNo}', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('$occupied / ${room.capacity} beds', style: textTheme.bodySmall),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: primary.withValues(alpha: 0.15),
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
