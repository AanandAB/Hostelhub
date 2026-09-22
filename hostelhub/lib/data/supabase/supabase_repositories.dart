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
import '../models/pricing.dart';
import '../models/poll.dart';
import '../models/poll_response.dart';
import '../models/property.dart';
import '../models/rating.dart';
import '../models/rent_plan.dart';
import '../models/room.dart';
import '../models/sos_alert.dart';
import '../models/user.dart';
import '../models/visitor.dart';
import '../repositories/repositories.dart';

/// Supabase (Postgres) implementations — STUBS.
///
/// Wire these to the supabase_flutter SDK once SUPABASE_URL + anon key are set:
///   - auth     → supabase.auth.signInWithPassword / signUp
///   - data     → supabase.from('properties').select().eq('owner_id', ...)
///   - realtime → supabase.channel('polls').onPostgresChanges(...)
/// Tenant isolation is enforced by Postgres RLS on `tenant_id` (doc §7).
class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<User> login(String username, String password) {
    throw UnimplementedError(
        'Supabase backend not wired — set BACKEND=supabase after configuring keys');
  }

  @override
  Future<User> register(User user, String password) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<void> forgotPassword(String email) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<void> resetPassword(String token, String password) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<void> logout() async {}
}

class SupabasePropertyRepository implements PropertyRepository {
  @override
  Future<List<Property>> listProperties(String ownerId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Property> createProperty(Property property) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Property> getProperty(String id) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Property> updateProperty(String id,
      {String? type, Map<String, bool>? features}) {
    throw UnimplementedError('Supabase backend not wired');
  }
}

class SupabasePollRepository implements PollRepository {
  @override
  Future<List<Poll>> listPolls(String propertyId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Poll> createPoll(Poll poll) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<PollResponse> respond(PollResponse response) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<List<PollResponse>> listResponses(String pollId) {
    throw UnimplementedError('Supabase backend not wired');
  }
}

class SupabaseRoomRepository implements RoomRepository {
  @override
  Future<List<Room>> listRooms(String propertyId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Room> createRoom(Room room) {
    throw UnimplementedError('Supabase backend not wired');
  }
}

class SupabaseInmateRepository implements InmateRepository {
  @override
  Future<List<Inmate>> listInmates(String propertyId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
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
  }) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Inmate> changeRoom(String inmateId,
      {required String roomId, required int bedNo}) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String inmateId, {String? month}) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Map<String, dynamic>> emailInvoice(String inmateId, {String? month}) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Map<String, dynamic>> regenerateCredentials(String inmateId) {
    throw UnimplementedError('Supabase backend not wired');
  }
}

class SupabaseRentRepository implements RentRepository {
  @override
  Future<RentPlan?> getRentPlan(String inmateId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<List<Payment>> listPayments(String inmateId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<List<Payment>> listPropertyPayments(String propertyId) {
    throw UnimplementedError('Supabase backend not wired');
  }

  @override
  Future<Payment> payRent({
    required String inmateId,
    required int amount,
    required String dueDate,
  }) {
    throw UnimplementedError('Supabase backend not wired');
  }
}

class SupabaseOpsRepository implements OpsRepository {
  Never _n() => throw UnimplementedError('Supabase backend not wired');

  @override
  Future<List<Complaint>> listComplaints(String propertyId) => _n();
  @override
  Future<List<Complaint>> listInmateComplaints(String inmateId) => _n();
  @override
  Future<Complaint> createComplaint(Complaint complaint) => _n();
  @override
  Future<Complaint> updateComplaintStatus(
          String complaintId, String status) =>
      _n();
  @override
  Future<List<Notice>> listNotices(String propertyId) => _n();
  @override
  Future<Notice> createNotice(Notice notice) => _n();
  @override
  Future<List<Visitor>> listVisitors(String propertyId) => _n();
  @override
  Future<Visitor> createVisitor(Visitor visitor) => _n();
  @override
  Future<Visitor> checkOutVisitor(String visitorId) => _n();
  @override
  Future<List<LeaveRecord>> listLeave(String propertyId) => _n();
  @override
  Future<List<LeaveRecord>> listInmateLeave(String inmateId) => _n();
  @override
  Future<LeaveRecord> createLeave(LeaveRecord record) => _n();
  @override
  Future<List<Deposit>> listDeposits(String propertyId) => _n();
  @override
  Future<Deposit?> getInmateDeposit(String inmateId) => _n();
  @override
  Future<Deposit> createDeposit(Deposit deposit) => _n();
  @override
  Future<Deposit> addDepositDeduction(
          String depositId, String reason, int amount) =>
      _n();
  @override
  Future<List<CheckoutRequest>> listCheckouts(String propertyId) => _n();
  @override
  Future<CheckoutRequest> createCheckout(CheckoutRequest request) => _n();

  @override
  Future<CheckoutRequest> completeCheckout(String checkoutId,
          {int refund = 0, int forfeit = 0}) =>
      _n();

  @override
  Future<List<ChatMessage>> listMessages(String inmateId) => _n();
  @override
  Future<ChatMessage> sendMessage({
    required String inmateId,
    required String senderId,
    required String senderRole,
    required String text,
  }) =>
      _n();
  @override
  Future<List<Expense>> listExpenses(String propertyId) => _n();
  @override
  Future<Expense> createExpense(Expense expense) => _n();
  @override
  Future<Pnl> getPnl(String propertyId) => _n();
  @override
  Future<List<Rating>> listRatings(String propertyId) => _n();
  @override
  Future<Rating> createRating(Rating rating) => _n();
  @override
  Future<List<SosAlert>> listSos(String propertyId) => _n();
  @override
  Future<SosAlert> createSos(SosAlert alert) => _n();
  @override
  Future<SosAlert> acknowledgeSos(String alertId) => _n();

  @override
  Future<List<Document>> listDocuments(
          String ownerType, String ownerId) =>
      _n();
  @override
  Future<Document> createDocument(Document document) => _n();
  @override
  Future<Document> updateDocument(String documentId,
          {String? name, String? type}) =>
      _n();
  @override
  Future<void> deleteDocument(String documentId) => _n();
}

class SupabaseAdminRepository implements AdminRepository {
  @override
  Future<PricingConfig> getPricing() =>
      throw UnimplementedError('Supabase backend not wired');
  @override
  Future<PricingConfig> updatePricing(Pricing pricing) =>
      throw UnimplementedError('Supabase backend not wired');
  @override
  Future<PricingConfig> setOverride(String ownerId, Pricing? pricing) =>
      throw UnimplementedError('Supabase backend not wired');
  @override
  Future<List<User>> listOwners() =>
      throw UnimplementedError('Supabase backend not wired');
}
