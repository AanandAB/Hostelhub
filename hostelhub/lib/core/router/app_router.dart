import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/user.dart';
import '../../features/auth/auth_controller.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/inmates/add_inmate_screen.dart';
import '../../features/onboarding/setup_screen.dart';
import '../../features/ops/chat_screen.dart';
import '../../features/ops/complaints_screen.dart';
import '../../features/ops/deposits_checkout_screen.dart';
import '../../features/ops/documents_screen.dart';
import '../../features/ops/expenses_screen.dart';
import '../../features/ops/property_settings_screen.dart';
import '../../features/ops/ratings_screen.dart';
import '../../features/ops/sos_screen.dart';
import '../../features/ops/visitors_leave_screen.dart';
import '../../features/shell/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Re-evaluate redirects whenever auth state changes (login/logout/bootstrap).
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (prev, next) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final loggedIn = auth.user != null;
      final onAuth = loc == '/login' || loc == '/register';
      final ownerOnly = loc == '/setup' ||
          loc == '/inmates/new' ||
          loc == '/complaints' ||
          loc == '/visitors' ||
          loc == '/leave' ||
          loc == '/deposits' ||
          loc == '/checkout' ||
          loc == '/chat' ||
          loc == '/expenses' ||
          loc == '/ratings' ||
          loc == '/sos' ||
          loc == '/settings';
      final inmateOnly = loc == '/complaints/new' ||
          loc == '/leave/new' ||
          loc == '/deposit';

      // While the persisted session loads, hold on the splash screen.
      if (auth.loading) {
        return loc == '/splash' ? null : '/splash';
      }
      if (loggedIn && (onAuth || loc == '/splash')) return '/home';
      if (!loggedIn && !onAuth) return '/login';
      if (ownerOnly && auth.user!.role != UserRole.owner) return '/home';
      if (inmateOnly && auth.user!.role != UserRole.inmate) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const AppShell()),
      GoRoute(path: '/setup', builder: (_, _) => const SetupScreen()),
      GoRoute(path: '/inmates/new', builder: (_, _) => const AddInmateScreen()),
      GoRoute(path: '/complaints', builder: (_, _) => const ComplaintsScreen()),
      GoRoute(
          path: '/complaints/new',
          builder: (_, _) => const RaiseComplaintScreen()),
      GoRoute(path: '/visitors', builder: (_, _) => const VisitorsScreen()),
      GoRoute(path: '/leave', builder: (_, _) => const LeaveScreen()),
      GoRoute(path: '/leave/new', builder: (_, _) => const MarkLeaveScreen()),
      GoRoute(path: '/deposits', builder: (_, _) => const DepositsScreen()),
      GoRoute(path: '/deposit', builder: (_, _) => const DepositViewScreen()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
      GoRoute(path: '/chat', builder: (_, _) => const ChatListScreen()),
      GoRoute(
          path: '/chat/:inmateId',
          builder: (_, state) =>
              ChatThreadScreen(inmateId: state.pathParameters['inmateId']!)),
      GoRoute(path: '/expenses', builder: (_, _) => const ExpensesScreen()),
      GoRoute(path: '/ratings', builder: (_, _) => const RatingsScreen()),
      GoRoute(path: '/sos', builder: (_, _) => const SosScreen()),
      GoRoute(path: '/documents', builder: (_, _) => const DocumentsScreen()),
      GoRoute(
          path: '/settings',
          builder: (_, _) => const PropertySettingsScreen()),
    ],
  );
});
