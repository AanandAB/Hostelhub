import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../services/payments/payment_gateway.dart';
import 'firebase/firebase_repositories.dart';
import 'local/local_api_client.dart';
import 'local/local_repositories.dart';
import 'repositories/repositories.dart';
import 'supabase/supabase_repositories.dart';

/// Builds the active [Backend] from [AppConfig.backend].
/// Swap implementations at build time: `--dart-define=BACKEND=supabase` etc.
final backendProvider = Provider<Backend>((ref) {
  // Payments always route through Razorpay in production; a mock is used when
  // no keys are configured so local/LAN testing needs no gateway account.
  final PaymentGateway payments = AppConfig.razorpayConfigured
      ? RazorpayGateway(
          keyId: AppConfig.razorpayKeyId,
          keySecret: AppConfig.razorpayKeySecret,
        )
      : MockPaymentGateway();

  switch (AppConfig.backend) {
    case BackendKind.supabase:
      return Backend(
        auth: SupabaseAuthRepository(),
        properties: SupabasePropertyRepository(),
        rooms: SupabaseRoomRepository(),
        inmates: SupabaseInmateRepository(),
        rent: SupabaseRentRepository(),
        polls: SupabasePollRepository(),
        ops: SupabaseOpsRepository(),
        admin: SupabaseAdminRepository(),
        payments: payments,
      );
    case BackendKind.firebase:
      return Backend(
        auth: FirebaseAuthRepository(),
        properties: FirebasePropertyRepository(),
        rooms: FirebaseRoomRepository(),
        inmates: FirebaseInmateRepository(),
        rent: FirebaseRentRepository(),
        polls: FirebasePollRepository(),
        ops: FirebaseOpsRepository(),
        admin: FirebaseAdminRepository(),
        payments: payments,
      );
    case BackendKind.local:
      final api = LocalApiClient(baseUrl: AppConfig.localBaseUrl);
      return Backend(
        auth: LocalAuthRepository(api),
        properties: LocalPropertyRepository(api),
        rooms: LocalRoomRepository(api),
        inmates: LocalInmateRepository(api),
        rent: LocalRentRepository(api),
        polls: LocalPollRepository(api),
        ops: LocalOpsRepository(api),
        admin: LocalAdminRepository(api),
        payments: payments,
      );
    case BackendKind.cloudflare:
      // Same REST contract as the local server, hosted on Workers + D1.
      final api = LocalApiClient(baseUrl: AppConfig.cloudflareBaseUrl);
      return Backend(
        auth: LocalAuthRepository(api),
        properties: LocalPropertyRepository(api),
        rooms: LocalRoomRepository(api),
        inmates: LocalInmateRepository(api),
        rent: LocalRentRepository(api),
        polls: LocalPollRepository(api),
        ops: LocalOpsRepository(api),
        admin: LocalAdminRepository(api),
        payments: payments,
      );
  }
});
