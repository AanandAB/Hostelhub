import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';
import '../../presentation/widgets/glass_bottom_nav.dart';
import '../auth/auth_controller.dart';
import '../inmates/inmates_screen.dart';
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

  List<_Tab> _tabsFor(UserRole role) {
    if (role == UserRole.owner) {
      return const [
        _Tab(Icons.dashboard_rounded, 'Home', HomeScreen()),
        _Tab(Icons.people_alt_rounded, 'Inmates', InmatesScreen()),
        _Tab(Icons.restaurant_rounded, 'Polls', PollsScreen()),
        _Tab(Icons.more_horiz_rounded, 'More', MoreScreen()),
      ];
    }
    return const [
      _Tab(Icons.home_rounded, 'Home', HomeScreen()),
      _Tab(Icons.payments_rounded, 'Payments', PaymentsScreen()),
      _Tab(Icons.campaign_rounded, 'Notices', NoticesScreen()),
      _Tab(Icons.more_horiz_rounded, 'More', MoreScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final role =
        ref.watch(authControllerProvider).user?.role ?? UserRole.inmate;
    final tabs = _tabsFor(role);

    return Scaffold(
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
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final Widget screen;
  const _Tab(this.icon, this.label, this.screen);
}
