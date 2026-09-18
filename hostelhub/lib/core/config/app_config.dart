/// Central configuration for HostelHub.
///
/// Every backend/payment credential lives here and is injected via
/// `--dart-define` at build/run time, so secrets never ship in source control.
///
/// Usage:
///   flutter run --dart-define=BACKEND=local \
///               --dart-define=LOCAL_BASE_URL=http://192.168.1.10:8080
///
/// Supported BACKEND values: local | supabase | firebase
library;

/// Which backend the app talks to.
enum BackendKind { local, supabase, firebase, cloudflare }

class AppConfig {
  AppConfig._(); // static config only — no instances

  /// Active backend, selected at build time. Defaults to `local` (LAN testing).
  static String get backendName =>
      const String.fromEnvironment('BACKEND', defaultValue: 'local');

  static BackendKind get backend => switch (backendName) {
        'supabase' => BackendKind.supabase,
        'firebase' => BackendKind.firebase,
        'cloudflare' => BackendKind.cloudflare,
        _ => BackendKind.local,
      };

  // ── Local test server (LAN) ────────────────────────────────────────────────
  /// Base URL of the local Dart shelf server (server/bin/server.dart).
  /// Point this at your dev machine's LAN IP so a second device can reach it.
  static String get localBaseUrl => const String.fromEnvironment(
        'LOCAL_BASE_URL',
        defaultValue: 'http://127.0.0.1:8081',
      );

  /// Base URL of the Cloudflare Workers backend (see workers/).
  static String get cloudflareBaseUrl => const String.fromEnvironment(
        'CLOUDFLARE_BASE_URL',
        defaultValue: '',
      );

  // ── Supabase (placeholder) ─────────────────────────────────────────────────
  /// Project URL + anon key from Supabase dashboard → Project Settings → API.
  /// Empty strings mean "not configured" (backend falls back safely).
  static String get supabaseUrl =>
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get supabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  // ── Firebase (placeholder) ─────────────────────────────────────────────────
  /// Firebase is configured via google-services.json / GoogleService-Info.plist
  /// plus an optional FCM service-account key for push. See the top-level README.
  static bool get firebaseConfigured =>
      const bool.fromEnvironment('FIREBASE_CONFIG', defaultValue: false);

  // ── Razorpay (placeholder) ─────────────────────────────────────────────────
  /// Live keys go here once you have a Razorpay merchant account.
  /// While empty, the app uses a MockPaymentGateway so local testing works.
  static String get razorpayKeyId =>
      const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: '');

  static String get razorpayKeySecret =>
      const String.fromEnvironment('RAZORPAY_KEY_SECRET', defaultValue: '');

  static bool get razorpayConfigured => razorpayKeyId.isNotEmpty;
}
