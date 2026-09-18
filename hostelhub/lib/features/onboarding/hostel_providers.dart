import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/inmate.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../data/models/user.dart';
import '../auth/auth_controller.dart';

/// The logged-in owner's properties (multi-property ready).
final propertiesProvider = FutureProvider<List<Property>>((ref) async {
  final user = ref.watch(authControllerProvider).user;
  if (user == null || user.role != UserRole.owner) return const [];
  return ref.watch(backendProvider).properties.listProperties(user.id);
});

/// Notifier holding the currently selected property id (null = first).
class SelectedPropertyNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

/// Currently selected property id (null = auto-select the first).
final selectedPropertyIdProvider =
    NotifierProvider<SelectedPropertyNotifier, String?>(
        SelectedPropertyNotifier.new);

/// The property the owner is currently managing (selected, or first).
final currentPropertyProvider = FutureProvider<Property?>((ref) async {
  final props = await ref.watch(propertiesProvider.future);
  if (props.isEmpty) return null;
  final selected = ref.watch(selectedPropertyIdProvider);
  if (selected != null) {
    for (final p in props) {
      if (p.id == selected) return p;
    }
  }
  return props.first;
});

/// A single property by id (used by inmates to read feature toggles).
final propertyProvider = FutureProvider.family<Property?, String>(
    (ref, id) => ref.watch(backendProvider).properties.getProperty(id));

/// Rooms for a property, keyed by propertyId.
final roomsProvider = FutureProvider.family<List<Room>, String>(
    (ref, propertyId) => ref.watch(backendProvider).rooms.listRooms(propertyId));

/// Inmates for a property, keyed by propertyId.
final inmatesProvider = FutureProvider.family<List<Inmate>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).inmates.listInmates(propertyId));
