import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/glass.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) {
      _snack('Enter your username and password');
      return;
    }
    setState(() => _loading = true);
    final error = await ref
        .read(authControllerProvider.notifier)
        .login(_username.text.trim(), _password.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) _snack(error);
    // Success: the router redirect handles navigation to /home.
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
                  Text('Welcome back', style: textTheme.displayLarge),
                  const SizedBox(height: 6),
                  Text(
                    'Log in to manage your hostel or your stay.',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  GlassTextField(
                    controller: _username,
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    controller: _password,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.go('/forgot-password'),
                      child: Text(
                        'Forgot password?',
                        style: textTheme.bodyMedium?.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassButton(
                    label: 'Log in',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ", style: textTheme.bodyMedium),
                      GestureDetector(
                        onTap: () => context.go('/register'),
                        child: Text(
                          'Sign up',
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
