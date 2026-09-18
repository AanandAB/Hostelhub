/// Payment abstraction. Razorpay is the chosen gateway (product doc §6).
///
/// Rent collects via UPI Autopay mandates; manual pay (UPI/card/netbanking)
/// via a one-time order. All amounts are in PAISE (Razorpay convention).
library;

/// A one-time payment order.
class PaymentOrder {
  final String orderId;
  final String currency; // 'INR'
  final int amount; // paise
  final String? receiptId;

  const PaymentOrder({
    required this.orderId,
    this.currency = 'INR',
    required this.amount,
    this.receiptId,
  });
}

/// A UPI Autopay mandate (recurring rent).
class AutopayMandate {
  final String mandateId;
  final String status; // active | pending | failed
  const AutopayMandate({required this.mandateId, required this.status});
}

abstract class PaymentGateway {
  /// Create a one-time payment order for manual pay.
  Future<PaymentOrder> createOrder({
    required int amountPaise,
    required String receiptId,
  });

  /// Verify a payment signature returned by the client SDK after a successful
  /// checkout, before trusting the payment as complete.
  Future<bool> verifySignature({
    required String orderId,
    required String paymentId,
    required String signature,
  });

  /// Authorize a UPI Autopay mandate for recurring rent.
  ///
  /// NOTE: live mandates require an approved Razorpay merchant + bank/NBFC
  /// sponsorship (eMandate). Until then this is a placeholder. See doc §6.
  Future<AutopayMandate> createAutopayMandate({
    required String customerId,
    required int maxAmountPaise,
    required String frequency,
  });
}

/// Real Razorpay gateway. Stubbed — wire to the Razorpay APIs once keys exist.
class RazorpayGateway implements PaymentGateway {
  final String keyId;
  final String keySecret;

  RazorpayGateway({required this.keyId, required this.keySecret});

  @override
  Future<PaymentOrder> createOrder({
    required int amountPaise,
    required String receiptId,
  }) {
    // TODO(Razorpay): POST https://api.razorpay.com/v1/orders with Basic auth
    // (keyId:keySecret). Body: {amount, currency:'INR', receipt}. Return order_id.
    throw UnimplementedError(
        'Razorpay createOrder not wired yet — see payment_gateway.dart TODO');
  }

  @override
  Future<bool> verifySignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) {
    // TODO(Razorpay): server-side HMAC-SHA256(order_id + "|" + payment_id,
    // keySecret) == signature. Never trust a client-supplied success flag.
    throw UnimplementedError(
        'Razorpay verifySignature not wired yet — see payment_gateway.dart TODO');
  }

  @override
  Future<AutopayMandate> createAutopayMandate({
    required String customerId,
    required int maxAmountPaise,
    required String frequency,
  }) {
    // TODO(Razorpay): use the Recurring Payments (eMandate) API once the
    // merchant + bank sponsorship is approved. Returns a mandate_id to store on
    // the RentPlan.
    throw UnimplementedError(
        'Razorpay createAutopayMandate not wired yet — see payment_gateway.dart TODO');
  }
}

/// Local-testing gateway. Returns fake successes so the full payment flow can
/// be exercised on the LAN without real Razorpay keys.
class MockPaymentGateway implements PaymentGateway {
  @override
  Future<PaymentOrder> createOrder({
    required int amountPaise,
    required String receiptId,
  }) async {
    return PaymentOrder(
      orderId: 'local_${DateTime.now().millisecondsSinceEpoch}',
      amount: amountPaise,
      receiptId: receiptId,
    );
  }

  @override
  Future<bool> verifySignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async =>
      true;

  @override
  Future<AutopayMandate> createAutopayMandate({
    required String customerId,
    required int maxAmountPaise,
    required String frequency,
  }) async =>
      const AutopayMandate(mandateId: 'local_mandate', status: 'active');
}
