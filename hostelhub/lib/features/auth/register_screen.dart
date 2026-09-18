import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/glass.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _owner = true;
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _username.text.trim().isEmpty ||
        _password.text.isEmpty) {
      _snack('Fill in name, username and password');
      return;
    }
    setState(() => _loading = true);
    final error = await ref.read(authControllerProvider.notifier).register(
          role: _owner ? 'owner' : 'inmate',
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          username: _username.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) _snack(error);
  }

  void _snack(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;

    return Scaffold(
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Create account', style: textTheme.displayLarge),
                  const SizedBox(height: 6),
                  Text('Hostel owner or inmate — pick your role.',
                      style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _RolePill(
                          label: 'Hostel owner',
                          icon: Icons.apartment_rounded,
                          selected: _owner,
                          onTap: () => setState(() => _owner = true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _RolePill(
                          label: 'Inmate',
                          icon: Icons.person_rounded,
                          selected: !_owner,
                          onTap: () => setState(() => _owner = false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GlassTextField(
                      controller: _name, label: 'Full name', icon: Icons.badge_outlined),
                  const SizedBox(height: 14),
                  GlassTextField(
                    controller: _phone,
                    label: 'Phone (optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                      controller: _username, label: 'Username', icon: Icons.person_outline),
                  const SizedBox(height: 14),
                  GlassTextField(
                      controller: _password, label: 'Password', icon: Icons.lock_outline, obscure: true),
                  const SizedBox(height: 24),
                  GlassButton(
                    label: 'Create account',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'Log in',
                          style: textTheme.bodyLarge?.copyWith(
                            color: primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RolePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    final muted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        tint: selected ? primary.withValues(alpha: 0.18) : null,
        child: Column(
          children: [
            Icon(icon, color: selected ? primary : muted, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? primary : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
