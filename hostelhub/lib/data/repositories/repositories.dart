import '../../services/payments/payment_gateway.dart';
import '../models/chat_message.dart';
import '../models/checkout_request.dart';
import '../models/complaint.dart';
import '../models/deposit.dart';
import '../models/document.dart';
import '../models/expense.dart';
import '../models/inmate.dart';
import '../models/leave_record.dart';
import '../models/notice.dart';
import '../models/payment.dart';
import '../models/poll.dart';
import '../models/poll_response.dart';
import '../models/pricing.dart';
import '../models/property.dart';
import '../models/rating.dart';
import '../models/rent_plan.dart';
import '../models/room.dart';
import '../models/sos_alert.dart';
import '../models/user.dart';
import '../models/visitor.dart';

/// Authentication: login, registration, and session handling.
abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<User> register(User user, String password);
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String password);
  Future<User?> currentUser();
  Future<void> logout();
}

/// Property / hostel profile management (multi-property ready).
abstract class PropertyRepository {
  Future<List<Property>> listProperties(String ownerId);
  Future<Property> getProperty(String id);
  Future<Property> createProperty(Property property);
  Future<Property> updateProperty(String id,
      {String? type, Map<String, bool>? features});
}

/// Rooms within a property.
abstract class RoomRepository {
  Future<List<Room>> listRooms(String propertyId);
  Future<Room> createRoom(Room room);
}

/// Result of onboarding an inmate: the created record plus the auto-generated
/// temporary password the owner shares so the inmate can log in.
class NewInmate {
  final Inmate inmate;
  final String password;
  const NewInmate({required this.inmate, required this.password});
}

/// Inmate (ward) management: list + onboard with room/bed + rent assignment.
abstract class InmateRepository {
  Future<List<Inmate>> listInmates(String propertyId);

  Future<NewInmate> createInmate({
    required String propertyId,
    required String name,
    required String phone,
    required String email,
    required String roomId,
    required int bedNo,
    required int rentAmount,
    required int dueDay,
    required String joinDate,
  });

  /// Reassign an inmate to a different room/bed (hostel/PG only).
  Future<Inmate> changeRoom(String inmateId,
      {required String roomId, required int bedNo});

  /// Fetch the structured per-inmate invoice data.
  Future<Map<String, dynamic>> getInvoice(String inmateId, {String? month});

  /// Email the invoice to the inmate's address; returns `{sent, to, invoice}`.
  Future<Map<String, dynamic>> emailInvoice(String inmateId, {String? month});

  /// Regenerate the inmate's login credentials; returns `{username, password}`.
  Future<Map<String, dynamic>> regenerateCredentials(String inmateId);
}

/// Rent plans + payments for the rent engine.
abstract class RentRepository {
  Future<RentPlan?> getRentPlan(String inmateId);
  Future<List<Payment>> listPayments(String inmateId);
  Future<List<Payment>> listPropertyPayments(String propertyId);
  Future<Payment> payRent({
    required String inmateId,
    required int amount,
    required String dueDate,
  });
}

/// Mess food polls: list, create, respond.
abstract class PollRepository {
  Future<List<Poll>> listPolls(String propertyId);
  Future<Poll> createPoll(Poll poll);
  Future<PollResponse> respond(PollResponse response);
  Future<List<PollResponse>> listResponses(String pollId);
}

/// Day-to-day operations (doc §3.5–3.10): complaints, notices, visitors,
/// leave, deposits, checkout. One interface keeps the six near-identical
/// repo stacks from multiplying; split later if any domain grows.
abstract class OpsRepository {
  // ── Complaints ──────────────────────────────────────────────────────────
  Future<List<Complaint>> listComplaints(String propertyId);
  Future<List<Complaint>> listInmateComplaints(String inmateId);
  Future<Complaint> createComplaint(Complaint complaint);
  Future<Complaint> updateComplaintStatus(String complaintId, String status);

  // ── Notices ─────────────────────────────────────────────────────────────
  Future<List<Notice>> listNotices(String propertyId);
  Future<Notice> createNotice(Notice notice);

  // ── Visitors ────────────────────────────────────────────────────────────
  Future<List<Visitor>> listVisitors(String propertyId);
  Future<Visitor> createVisitor(Visitor visitor);
  Future<Visitor> checkOutVisitor(String visitorId);

  // ── Leave ───────────────────────────────────────────────────────────────
  Future<List<LeaveRecord>> listLeave(String propertyId);
  Future<List<LeaveRecord>> listInmateLeave(String inmateId);
  Future<LeaveRecord> createLeave(LeaveRecord record);

  // ── Deposits ────────────────────────────────────────────────────────────
  Future<List<Deposit>> listDeposits(String propertyId);
  Future<Deposit?> getInmateDeposit(String inmateId);
  Future<Deposit> createDeposit(Deposit deposit);
  Future<Deposit> addDepositDeduction(String depositId, String reason, int amount);

  // ── Checkout ────────────────────────────────────────────────────────────
  Future<List<CheckoutRequest>> listCheckouts(String propertyId);
  Future<CheckoutRequest> createCheckout(CheckoutRequest request);
  Future<CheckoutRequest> completeCheckout(String checkoutId,
      {int refund = 0, int forfeit = 0});

  // ── Chat ───────────────────────────────────────────────────────────────
  Future<List<ChatMessage>> listMessages(String inmateId);
  Future<ChatMessage> sendMessage({
    required String inmateId,
    required String senderId,
    required String senderRole,
    required String text,
  });

  // ── Expenses & P&L ─────────────────────────────────────────────────────
  Future<List<Expense>> listExpenses(String propertyId);
  Future<Expense> createExpense(Expense expense);
  Future<Pnl> getPnl(String propertyId);

  // ── Ratings ────────────────────────────────────────────────────────────
  Future<List<Rating>> listRatings(String propertyId);
  Future<Rating> createRating(Rating rating);

  // ── SOS ────────────────────────────────────────────────────────────────
  Future<List<SosAlert>> listSos(String propertyId);
  Future<SosAlert> createSos(SosAlert alert);
  Future<SosAlert> acknowledgeSos(String alertId);

  // ── Document vault ─────────────────────────────────────────────────────
  Future<List<Document>> listDocuments(String ownerType, String ownerId);
  Future<Document> createDocument(Document document);
}

/// Super-admin (SaaS operator) surface: subscription pricing + client overrides.
abstract class AdminRepository {
  Future<PricingConfig> getPricing();
  Future<PricingConfig> updatePricing(Pricing pricing);
  /// Sets or clears (`pricing == null`) a per-owner override.
  Future<PricingConfig> setOverride(String ownerId, Pricing? pricing);
  Future<List<User>> listOwners();
}

/// Aggregate of every backend capability. Swapped wholesale by `backendProvider`
/// based on `AppConfig.backend` — callers depend on these interfaces, never on
/// a concrete implementation.
class Backend {
  final AuthRepository auth;
  final PropertyRepository properties;
  final RoomRepository rooms;
  final InmateRepository inmates;
  final RentRepository rent;
  final PollRepository polls;
  final OpsRepository ops;
  final AdminRepository admin;
  final PaymentGateway payments;

  const Backend({
    required this.auth,
    required this.properties,
    required this.rooms,
    required this.inmates,
    required this.rent,
    required this.polls,
    required this.ops,
    required this.admin,
    required this.payments,
  });
}
