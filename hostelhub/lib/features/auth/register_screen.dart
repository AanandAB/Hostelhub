import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../presentation/widgets/glass.dart';
import 'auth_controller.dart';

/// Owner-only sign-up. Inmates are onboarded by their owner (auto-generated
/// credentials), so they never self-register.
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
    if (_password.text.length < 8) {
      _snack('Password must be at least 8 characters');
      return;
    }
    final phoneErr = Validators.phoneError(_phone.text.trim());
    if (phoneErr != null) {
      _snack(phoneErr);
      return;
    }
    setState(() => _loading = true);
    final error = await ref.read(authControllerProvider.notifier).register(
          role: 'owner',
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
                  Text('Create your account as a property owner.',
                      style: textTheme.bodyMedium),
                  const SizedBox(height: 24),
                  GlassTextField(
                      controller: _name,
                      label: 'Full name',
                      icon: Icons.badge_outlined),
                  const SizedBox(height: 14),
                  GlassTextField(
                    controller: _phone,
                    label: 'Phone (optional)',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                      controller: _username,
                      label: 'Username',
                      icon: Icons.person_outline),
                  const SizedBox(height: 14),
                  GlassTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true),
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
                      Text('Already have an account? ',
                          style: textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.push('/login'),
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
