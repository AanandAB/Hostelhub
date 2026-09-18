import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/inmate.dart';
import '../../data/models/payment.dart';
import '../../data/models/poll.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../data/models/sos_alert.dart';
import '../../data/models/user.dart';
import '../../presentation/widgets/due_ring.dart';
import '../../presentation/widgets/glass.dart';
import '../auth/auth_controller.dart';
import '../onboarding/hostel_providers.dart';
import '../ops/notices_screen.dart';
import '../ops/ratings_screen.dart';
import '../polls/poll_providers.dart';
import '../polls/polls_screen.dart';
import '../rent/pay_flow.dart';
import '../rent/rent_providers.dart';

/// Home / dashboard tab. Owner sees live hostel stats (or a setup CTA);
/// inmates see a placeholder until their data lands in later phases.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final isOwner = user?.role == UserRole.owner;

    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: isOwner
            ? _buildOwner(context, ref, user, textTheme)
            : _buildInmate(context, ref, user, textTheme),
      ),
    );
  }

  // ── Owner ────────────────────────────────────────────────────────────────
  Widget _buildOwner(
      BuildContext context, WidgetRef ref, User? user, TextTheme textTheme) {
    return ref.watch(currentPropertyProvider).when(
          data: (prop) {
            if (prop == null) return _setupPrompt(context, user, textTheme);
            final rooms =
                ref.watch(roomsProvider(prop.id)).value ?? const <Room>[];
            final inmates = ref.watch(inmatesProvider(prop.id)).value ??
                const <Inmate>[];
            final totalBeds =
                rooms.fold<int>(0, (sum, r) => sum + r.capacity);
            final occupancyPct = totalBeds == 0
                ? 0
                : ((inmates.length / totalBeds) * 100).round();
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primary = isDark ? AppColors.primaryDark : AppColors.primary;

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              children: [
                Text('Welcome back', style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(user?.name ?? 'Owner', style: textTheme.displayLarge),
                const SizedBox(height: 4),
                Text(prop.name, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
                _propertySwitcher(context, ref, prop.id),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people_alt_rounded,
                        label: 'Inmates',
                        value: '${inmates.length}',
                        accent: primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bed_rounded,
                        label: 'Occupancy',
                        value: '$occupancyPct%',
                        accent: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.door_sliding_rounded,
                        label: 'Rooms',
                        value: '${rooms.length}',
                        accent: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.report_problem_rounded,
                        label: 'Open complaints',
                        value: '—',
                        accent: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick actions', style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        'Onboard inmates, set rent, and run mess polls from the tabs below.',
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
              child: Text('Error loading hostel', style: textTheme.bodyMedium)),
        );
  }

  Widget _setupPrompt(BuildContext context, User? user, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text('Welcome back', style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(user?.name ?? 'Owner', style: textTheme.displayLarge),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.apartment_rounded, size: 36, color: primary),
              const SizedBox(height: 12),
              Text('Set up your hostel', style: textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Create your hostel profile and add rooms to start onboarding inmates.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              GlassButton(
                label: 'Get started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go('/setup'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _propertySwitcher(
      BuildContext context, WidgetRef ref, String currentId) {
    final props = ref.watch(propertiesProvider).value ?? const <Property>[];
    if (props.length < 2) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final idleColor = isDark ? AppColors.glassDark : AppColors.glassLight;
    final idleText = isDark ? AppColors.textDark : AppColors.textLight;
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final p in props)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () =>
                    ref.read(selectedPropertyIdProvider.notifier).select(p.id),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.id == currentId ? primary : idleColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    p.name,
                    style: TextStyle(
                      color: p.id == currentId ? Colors.white : idleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Inmate ───────────────────────────────────────────────────────────────
  Widget _buildInmate(
      BuildContext context, WidgetRef ref, User? user, TextTheme textTheme) {
    final inmateId = user?.id ?? '';
    final plan = ref.watch(rentPlanProvider(inmateId)).value;
    final payments =
        ref.watch(paymentsProvider(inmateId)).value ?? const <Payment>[];

    final daysLeft = plan == null ? 0 : daysUntilDue(plan.dueDay);
    final paid = plan == null ? false : paidThisMonth(payments);

    final propertyId = user?.propertyId ?? '';
    final polls = ref.watch(pollsProvider(propertyId)).value ?? const <Poll>[];
    final latestPoll = polls.isEmpty ? null : polls.last;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      children: [
        Text('Welcome back', style: textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(user?.name ?? 'Guest', style: textTheme.displayLarge),
        const SizedBox(height: 4),
        Text('Inmate · Your stay at a glance', style: textTheme.bodyMedium),
        const SizedBox(height: 24),
        GlassCard(
          child: plan == null
              ? Text('Your owner has not set your rent yet.',
                  style: textTheme.bodyMedium)
              : Column(
                  children: [
                    Row(
                      children: [
                        DueRing(daysLeft: paid ? 30 : daysLeft),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rent', style: textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text('₹${plan.amount}/mo',
                                  style: textTheme.displayLarge),
                              const SizedBox(height: 6),
                              Text(
                                paid
                                    ? 'Paid this month'
                                    : 'Due on day ${plan.dueDay}',
                                style: textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      label: paid
                          ? 'Paid ✓'
                          : 'Pay rent ₹${plan.amount}',
                      onPressed: paid
                          ? null
                          : () => payRentAndShowReceipt(
                              context, ref, inmateId, plan.amount),
                    ),
                  ],
                ),
        ),
        if (latestPoll != null) ...[
          const SizedBox(height: 14),
          InmatePollCard(poll: latestPoll, inmateId: inmateId),
        ],
        const SizedBox(height: 14),
        _sosButton(context, ref, user),
      ],
    );
  }

  Widget _sosButton(BuildContext context, WidgetRef ref, User? user) {
    return GlassCard(
      tint: AppColors.danger.withValues(alpha: 0.14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.danger.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.sos_rounded,
                color: AppColors.danger, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency SOS',
                    style: Theme.of(context).textTheme.titleMedium),
                Text('Alerts your owner instantly',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _triggerSos(context, ref, user),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('SOS',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerSos(
      BuildContext context, WidgetRef ref, User? user) async {
    if (user == null) return;
    HapticFeedback.heavyImpact();
    await ref.read(backendProvider).ops.createSos(SosAlert(
          id: '',
          propertyId: user.propertyId ?? '',
          inmateId: user.id,
        ));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS alert sent to your owner')));
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Generic placeholder for tabs whose features land in later phases.
class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String phase;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: muted),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Coming in Phase $phase',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Account + hub tab: role-aware menu of ops modules + account + logout.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final isOwner = user?.role == UserRole.owner;
    final propertyId = ref.watch(currentPropertyProvider).value?.id ?? '';

    return GlassBackground(
      dark: isDark,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
          children: [
            Text(isOwner ? 'Manage' : 'Menu', style: textTheme.displayLarge),
            const SizedBox(height: 16),
            if (isOwner)
              ..._ownerItems(context, propertyId)
            else
              ..._inmateItems(context, user),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                children: [
                  _row(context, 'Name', user?.name ?? '—'),
                  const Divider(height: 20),
                  _row(context, 'Role', user?.role.name ?? '—'),
                  const Divider(height: 20),
                  _row(context, 'Username', user?.username ?? '—'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassButton(
              label: 'Log out',
              icon: Icons.logout_rounded,
              color: AppColors.danger,
              onPressed: () =>
                  ref.read(authControllerProvider.notifier).logout(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _ownerItems(BuildContext context, String propertyId) {
    return [
      _menuItem(context, Icons.report_problem_rounded, 'Complaints',
          () => context.go('/complaints')),
      _menuItem(context, Icons.chat_bubble_rounded, 'Chat',
          () => context.go('/chat')),
      _menuItem(context, Icons.campaign_rounded, 'Post notice', () {
        if (propertyId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Set up your hostel first')));
          return;
        }
        showDialog(
          context: context,
          builder: (_) => PostNoticeDialog(propertyId: propertyId),
        );
      }),
      _menuItem(context, Icons.people_rounded, 'Visitors',
          () => context.go('/visitors')),
      _menuItem(context, Icons.directions_walk_rounded, 'Leave / attendance',
          () => context.go('/leave')),
      _menuItem(context, Icons.account_balance_wallet_rounded, 'Deposits',
          () => context.go('/deposits')),
      _menuItem(context, Icons.logout_rounded, 'Checkout',
          () => context.go('/checkout')),
      _menuItem(context, Icons.receipt_long_rounded, 'Expenses & P&L',
          () => context.go('/expenses')),
      _menuItem(
          context, Icons.star_rounded, 'Ratings', () => context.go('/ratings')),
      _menuItem(
          context, Icons.sos_rounded, 'SOS alerts', () => context.go('/sos')),
      _menuItem(context, Icons.folder_rounded, 'Documents',
          () => context.go('/documents')),
      _menuItem(context, Icons.add_business_rounded, 'Add property',
          () => context.go('/setup')),
    ];
  }

  List<Widget> _inmateItems(BuildContext context, User? user) {
    return [
      _menuItem(context, Icons.chat_bubble_rounded, 'Chat with owner',
          () => context.go('/chat/${user?.id ?? ''}')),
      _menuItem(context, Icons.report_problem_rounded, 'Raise a complaint',
          () => context.go('/complaints/new')),
      _menuItem(context, Icons.directions_walk_rounded, 'Mark leave',
          () => context.go('/leave/new')),
      _menuItem(context, Icons.account_balance_wallet_rounded, 'My deposit',
          () => context.go('/deposit')),
      _menuItem(context, Icons.star_rounded, 'Rate my stay', () {
        final propId = user?.propertyId ?? '';
        if (user == null || propId.isEmpty) return;
        showDialog(
          context: context,
          builder: (_) => RateStayDialog(propertyId: propId, inmateId: user.id),
        );
      }),
      _menuItem(context, Icons.folder_rounded, 'Documents',
          () => context.go('/documents')),
    ];
  }

  Widget _menuItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, size: 22, color: primary),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: textTheme.bodyLarge)),
            Icon(Icons.chevron_right_rounded,
                size: 20,
                color:
                    isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Text(value, style: textTheme.bodyLarge),
      ],
    );
  }
}
