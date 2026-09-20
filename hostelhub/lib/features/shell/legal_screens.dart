import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../presentation/widgets/glass.dart';

/// Shared scaffold for legal/policy pages: a titled list of sections.
class _LegalScaffold extends StatelessWidget {
  final String title;
  final List<(String, String)> sections;
  const _LegalScaffold({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              for (final (h, body) in sections) ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(h, style: textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(body, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Privacy policy — plain-language, DPDP-aligned.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalScaffold(
        title: 'Privacy policy',
        sections: [
          (
            'What we collect',
            'Your name, phone number and email (when you provide them), your '
                'property and inmate details, rent and payment records, and '
                'messages, complaints and notices you create in the app.'
          ),
          (
            'Why we collect it',
            'To run your hostel: manage inmates, collect rent, log visitors and '
                'complaints, and send invoices and notices. We do not sell or '
                'share your data with third parties for advertising.'
          ),
          (
            'Payments',
            'Rent payments are processed through Razorpay. We never store your '
                'full card or UPI credentials — Razorpay handles those securely '
                'under its own terms.'
          ),
          (
            'Your rights',
            'You may access, correct, or request deletion of your personal data '
                'at any time by contacting us. We retain financial records only '
                'as long as required by law.'
          ),
          (
            'Security',
            'Passwords are stored hashed, sessions expire, and access to your '
                'property\'s data is restricted to you and the inmates you '
                'onboard. Contact us at support@hostelhub.app for any privacy '
                'question.'
          ),
        ],
      );
}

/// Terms & Conditions.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _LegalScaffold(
        title: 'Terms & Conditions',
        sections: [
          (
            'The service',
            'HostelHub is a property-management tool for hostel and rental '
                'owners. You are responsible for the accuracy of the data you '
                'enter and for how you use the app with your inmates.'
          ),
          (
            'Accounts',
            'Owner accounts are subject to the plan you subscribe to. Inmate '
                'accounts are created by the owner and inherit the owner\'s '
                'plan. Do not share login credentials.'
          ),
          (
            'Payments & billing',
            'Plans are billed monthly or yearly. Adding extra properties is '
                'billed per property. Rent collected from inmates is settled to '
                'your account via Razorpay, net of the platform fee.'
          ),
          (
            'Acceptable use',
            'Do not use the app for illegal activity, harassment, or to collect '
                'data you are not authorised to hold. We may suspend accounts '
                'that violate these terms.'
          ),
          (
            'Liability',
            'The app is provided as-is. We are not liable for indirect damages, '
                'payment disputes between you and your inmates, or downtime. '
                'Contact us at support@hostelhub.app.'
          ),
        ],
      );
}

/// Upgrade / pricing screen.
class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade plan'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text('Plans', style: textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'One property included. Add more as you grow.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _planCard(context, 'Monthly', 'Rs. 599', '/month',
                  ['1 property included', 'Unlimited inmates', 'All features'],
                  primary, true),
              const SizedBox(height: 14),
              _planCard(context, 'Yearly', 'Rs. 5,999', '/year',
                  ['1 property included', '2 months free', 'Priority support'],
                  AppColors.accent, false),
              const SizedBox(height: 14),
              _planCard(context, 'Extra property', 'Rs. 199', '/month each',
                  ['Add hostels, houses or offices', 'Billed per property'],
                  AppColors.warning, false),
              const SizedBox(height: 20),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payments', style: textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Online payment is being enabled soon. Until then, plans '
                      'are active and you can add up to 10 properties freely.',
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard(BuildContext context, String name, String price,
      String period, List<String> perks, Color accent, bool highlight) {
    final textTheme = Theme.of(context).textTheme;
    return GlassCard(
      tint: highlight ? accent.withValues(alpha: 0.10) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name, style: textTheme.titleLarge),
              ),
              Text.rich(TextSpan(
                children: [
                  TextSpan(
                      text: price,
                      style: textTheme.displayMedium?.copyWith(
                          color: accent, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' $period', style: textTheme.bodySmall),
                ],
              )),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 16, color: accent),
                  const SizedBox(width: 8),
                  Text(p, style: textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
