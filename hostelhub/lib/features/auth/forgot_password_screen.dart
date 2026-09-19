import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../presentation/widgets/glass.dart';

/// Password-reset step 1: enter the email on file. The server always returns
/// success (so it never reveals whether an account exists), then sends a
/// one-time, 15-minute reset link to that address.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _snack('Enter a valid email address');
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(backendProvider).auth.forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Could not send reset email: $e');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: _sent
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.mark_email_read_rounded,
                            size: 48, color: AppColors.accent),
                        const SizedBox(height: 16),
                        Text('Check your email',
                            style: textTheme.titleLarge,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        Text(
                          "If an account exists for that email, we've sent a "
                          'reset link (valid 15 minutes). Tap it to set a new '
                          'password.',
                          style: textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Forgot password',
                            style: textTheme.displayLarge),
                        const SizedBox(height: 6),
                        Text(
                          "Enter the email you were onboarded with. We'll send "
                          'a secure reset link.',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        GlassTextField(
                          controller: _email,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                          label: 'Send reset link',
                          loading: _loading,
                          onPressed: _submit,
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
