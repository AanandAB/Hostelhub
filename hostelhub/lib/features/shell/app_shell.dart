import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';
import '../../presentation/widgets/glass_bottom_nav.dart';
import '../auth/auth_controller.dart';
import '../inmates/inmates_screen.dart';
import '../onboarding/hostel_providers.dart';
import '../ops/notices_screen.dart';
import '../polls/polls_screen.dart';
import '../rent/payments_screen.dart';
import 'tab_screens.dart';

/// App shell: role-aware glass bottom nav + IndexedStack of tab screens.
/// Tab switching is local state for now; later phases can migrate to
/// StatefulShellRoute when tabs need deep links or per-tab state preservation.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  List<_Tab> _tabsFor(UserRole role, bool messEnabled, bool rentEnabled,
      bool noticesEnabled) {
    if (role == UserRole.owner) {
      return [
        _Tab(Icons.dashboard_rounded, 'Home', const HomeScreen()),
        _Tab(Icons.people_alt_rounded, 'Inmates', const InmatesScreen()),
        if (messEnabled)
          _Tab(Icons.restaurant_rounded, 'Polls', const PollsScreen()),
        _Tab(Icons.more_horiz_rounded, 'More', const MoreScreen()),
      ];
    }
    return [
      _Tab(Icons.home_rounded, 'Home', const HomeScreen()),
      if (rentEnabled)
        _Tab(Icons.payments_rounded, 'Payments', const PaymentsScreen()),
      if (noticesEnabled)
        _Tab(Icons.campaign_rounded, 'Notices', const NoticesScreen()),
      _Tab(Icons.more_horiz_rounded, 'More', const MoreScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final role = user?.role ?? UserRole.inmate;
    final isOwner = role == UserRole.owner;
    final prop = isOwner
        ? ref.watch(currentPropertyProvider).value
        : ((user?.propertyId ?? '').isNotEmpty
            ? ref.watch(propertyProvider(user!.propertyId!)).value
            : null);
    final messEnabled = prop?.featureEnabled('mess') ?? true;
    final rentEnabled = prop?.featureEnabled('rent') ?? true;
    final noticesEnabled = prop?.featureEnabled('notices') ?? true;
    final tabs = _tabsFor(role, messEnabled, rentEnabled, noticesEnabled);

    // Android back button: on a non-home tab, return to Home instead of
    // exiting the app; on Home, let the system back behave normally.
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: [for (final t in tabs) t.screen],
        ),
        bottomNavigationBar: GlassBottomNav(
          items: [for (final t in tabs) NavItem(icon: t.icon, label: t.label)],
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _Tab(this.icon, this.label, this.screen);
}
