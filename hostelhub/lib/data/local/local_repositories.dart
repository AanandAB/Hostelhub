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
import '../repositories/repositories.dart';
import 'local_api_client.dart';

/// Local-network implementations — talk to the Dart shelf server in /server.
/// These exercise the exact same interface the Supabase/Firebase impls will.

class LocalAuthRepository implements AuthRepository {
  final LocalApiClient api;
  LocalAuthRepository(this.api);

  @override
  Future<User> login(String username, String password) async {
    final json = await api.post('/auth/login', {
      'username': username,
      'password': password,
    });
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<User> register(User user, String password) async {
    final json = await api.post('/auth/register', {
      ...user.toJson(),
      'password': password,
    });
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  @override
  Future<void> forgotPassword(String email) async {
    await api.post('/auth/forgot-password', {'email': email});
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    await api.post('/auth/reset-password',
        {'token': token, 'password': password});
  }

  @override
  Future<User?> currentUser() async {
    // TODO(local): return the cached session user (from a session store).
    return null;
  }

  @override
  Future<void> logout() async {
    // TODO(local): clear the cached session.
  }
}

class LocalPropertyRepository implements PropertyRepository {
  final LocalApiClient api;
  LocalPropertyRepository(this.api);

  @override
  Future<List<Property>> listProperties(String ownerId) async {
    final json = await api.get('/properties?owner_id=$ownerId');
    return (json['properties'] as List<dynamic>? ?? const [])
        .map((e) => Property.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Property> createProperty(Property property) async {
    final json = await api.post('/properties', property.toJson());
    return Property.fromJson(json['property'] as Map<String, dynamic>);
  }

  @override
  Future<Property> getProperty(String id) async {
    final json = await api.get('/properties/$id');
    return Property.fromJson(json['property'] as Map<String, dynamic>);
  }

  @override
  Future<Property> updateProperty(String id,
      {String? type, Map<String, bool>? features}) async {
    final json = await api.patch('/properties/$id', {
      'type': ?type,
      'features': ?features,
    });
    return Property.fromJson(json['property'] as Map<String, dynamic>);
  }
}

class LocalPollRepository implements PollRepository {
  final LocalApiClient api;
  LocalPollRepository(this.api);

  @override
  Future<List<Poll>> listPolls(String propertyId) async {
    final json = await api.get('/polls?property_id=$propertyId');
    return (json['polls'] as List<dynamic>? ?? const [])
        .map((e) => Poll.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Poll> createPoll(Poll poll) async {
    final json = await api.post('/polls', poll.toJson());
    return Poll.fromJson(json['poll'] as Map<String, dynamic>);
  }

  @override
  Future<PollResponse> respond(PollResponse response) async {
    final json = await api.post(
        '/polls/${response.pollId}/respond', response.toJson());
    return PollResponse.fromJson(json['response'] as Map<String, dynamic>);
  }

  @override
  Future<List<PollResponse>> listResponses(String pollId) async {
    final json = await api.get('/polls/$pollId/responses');
    return (json['responses'] as List<dynamic>? ?? const [])
        .map((e) => PollResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class LocalRoomRepository implements RoomRepository {
  final LocalApiClient api;
  LocalRoomRepository(this.api);

  @override
  Future<List<Room>> listRooms(String propertyId) async {
    final json = await api.get('/rooms?property_id=$propertyId');
    return (json['rooms'] as List<dynamic>? ?? const [])
        .map((e) => Room.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Room> createRoom(Room room) async {
    final json = await api.post('/rooms', room.toJson());
    return Room.fromJson(json['room'] as Map<String, dynamic>);
  }
}

class LocalInmateRepository implements InmateRepository {
  final LocalApiClient api;
  LocalInmateRepository(this.api);

  @override
  Future<List<Inmate>> listInmates(String propertyId) async {
    final json = await api.get('/inmates?property_id=$propertyId');
    return (json['inmates'] as List<dynamic>? ?? const [])
        .map((e) => Inmate.fromJson(e as Map<String, dynamic>))
        .toList();
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
  }) async {
    final json = await api.post('/inmates', {
      'property_id': propertyId,
      'name': name,
      'phone': phone,
      'email': email,
      'room_id': roomId,
      'bed_no': bedNo,
      'rent_amount': rentAmount,
      'due_day': dueDay,
      'join_date': joinDate,
    });
    return NewInmate(
      inmate: Inmate.fromJson(json['inmate'] as Map<String, dynamic>),
      password: json['password'] as String,
    );
  }

  @override
  Future<Inmate> changeRoom(String inmateId,
      {required String roomId, required int bedNo}) async {
    final json = await api.patch('/inmates/$inmateId/room', {
      'room_id': roomId,
      'bed_no': bedNo,
    });
    return Inmate.fromJson(json['inmate'] as Map<String, dynamic>);
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String inmateId,
      {String? month}) async {
    final q = month == null ? '' : '?month=$month';
    final json = await api.get('/inmates/$inmateId/invoice$q');
    return json['invoice'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> emailInvoice(String inmateId,
      {String? month}) async {
    return await api.post('/inmates/$inmateId/invoice/email', {
      'month': ?month,
    });
  }

  @override
  Future<Map<String, dynamic>> regenerateCredentials(String inmateId) async {
    return await api.post('/inmates/$inmateId/credentials', {});
  }
}

class LocalRentRepository implements RentRepository {
  final LocalApiClient api;
  LocalRentRepository(this.api);

  @override
  Future<RentPlan?> getRentPlan(String inmateId) async {
    final json = await api.get('/rent-plans?inmate_id=$inmateId');
    final plan = json['rent_plan'];
    return plan == null
        ? null
        : RentPlan.fromJson(plan as Map<String, dynamic>);
  }

  @override
  Future<List<Payment>> listPayments(String inmateId) async {
    final json = await api.get('/payments?inmate_id=$inmateId');
    return (json['payments'] as List<dynamic>? ?? const [])
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Payment>> listPropertyPayments(String propertyId) async {
    final json = await api.get('/payments?property_id=$propertyId');
    return (json['payments'] as List<dynamic>? ?? const [])
        .map((e) => Payment.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Payment> payRent({
    required String inmateId,
    required int amount,
    required String dueDate,
  }) async {
    final json = await api.post('/payments', {
      'inmate_id': inmateId,
      'amount': amount,
      'due_date': dueDate,
    });
    return Payment.fromJson(json['payment'] as Map<String, dynamic>);
  }
}

class LocalOpsRepository implements OpsRepository {
  final LocalApiClient api;
  LocalOpsRepository(this.api);

  // ── Complaints ──────────────────────────────────────────────────────────
  @override
  Future<List<Complaint>> listComplaints(String propertyId) async {
    final json = await api.get('/complaints?property_id=$propertyId');
    return (json['complaints'] as List<dynamic>? ?? const [])
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Complaint>> listInmateComplaints(String inmateId) async {
    final json = await api.get('/complaints?inmate_id=$inmateId');
    return (json['complaints'] as List<dynamic>? ?? const [])
        .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Complaint> createComplaint(Complaint complaint) async {
    final json = await api.post('/complaints', complaint.toJson());
    return Complaint.fromJson(json['complaint'] as Map<String, dynamic>);
  }

  @override
  Future<Complaint> updateComplaintStatus(
      String complaintId, String status) async {
    final json =
        await api.post('/complaints/$complaintId/status', {'status': status});
    return Complaint.fromJson(json['complaint'] as Map<String, dynamic>);
  }

  // ── Notices ─────────────────────────────────────────────────────────────
  @override
  Future<List<Notice>> listNotices(String propertyId) async {
    final json = await api.get('/notices?property_id=$propertyId');
    return (json['notices'] as List<dynamic>? ?? const [])
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Notice> createNotice(Notice notice) async {
    final json = await api.post('/notices', notice.toJson());
    return Notice.fromJson(json['notice'] as Map<String, dynamic>);
  }

  // ── Visitors ────────────────────────────────────────────────────────────
  @override
  Future<List<Visitor>> listVisitors(String propertyId) async {
    final json = await api.get('/visitors?property_id=$propertyId');
    return (json['visitors'] as List<dynamic>? ?? const [])
        .map((e) => Visitor.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Visitor> createVisitor(Visitor visitor) async {
    final json = await api.post('/visitors', visitor.toJson());
    return Visitor.fromJson(json['visitor'] as Map<String, dynamic>);
  }

  @override
  Future<Visitor> checkOutVisitor(String visitorId) async {
    final json = await api.post('/visitors/$visitorId/checkout');
    return Visitor.fromJson(json['visitor'] as Map<String, dynamic>);
  }

  // ── Leave ───────────────────────────────────────────────────────────────
  @override
  Future<List<LeaveRecord>> listLeave(String propertyId) async {
    final json = await api.get('/leave?property_id=$propertyId');
    return (json['leave'] as List<dynamic>? ?? const [])
        .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LeaveRecord>> listInmateLeave(String inmateId) async {
    final json = await api.get('/leave?inmate_id=$inmateId');
    return (json['leave'] as List<dynamic>? ?? const [])
        .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<LeaveRecord> createLeave(LeaveRecord record) async {
    final json = await api.post('/leave', record.toJson());
    return LeaveRecord.fromJson(json['record'] as Map<String, dynamic>);
  }

  // ── Deposits ────────────────────────────────────────────────────────────
  @override
  Future<List<Deposit>> listDeposits(String propertyId) async {
    final json = await api.get('/deposits?property_id=$propertyId');
    return (json['deposits'] as List<dynamic>? ?? const [])
        .map((e) => Deposit.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Deposit?> getInmateDeposit(String inmateId) async {
    final json = await api.get('/deposits?inmate_id=$inmateId');
    final list = json['deposits'] as List<dynamic>? ?? const [];
    return list.isEmpty
        ? null
        : Deposit.fromJson(list.first as Map<String, dynamic>);
  }

  @override
  Future<Deposit> createDeposit(Deposit deposit) async {
    final json = await api.post('/deposits', deposit.toJson());
    return Deposit.fromJson(json['deposit'] as Map<String, dynamic>);
  }

  @override
  Future<Deposit> addDepositDeduction(
      String depositId, String reason, int amount) async {
    final json = await api
        .post('/deposits/$depositId/deduct', {'reason': reason, 'amount': amount});
    return Deposit.fromJson(json['deposit'] as Map<String, dynamic>);
  }

  // ── Checkout ────────────────────────────────────────────────────────────
  @override
  Future<List<CheckoutRequest>> listCheckouts(String propertyId) async {
    final json = await api.get('/checkouts?property_id=$propertyId');
    return (json['checkouts'] as List<dynamic>? ?? const [])
        .map((e) => CheckoutRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<CheckoutRequest> createCheckout(CheckoutRequest request) async {
    final json = await api.post('/checkouts', request.toJson());
    return CheckoutRequest.fromJson(json['checkout'] as Map<String, dynamic>);
  }

  @override
  Future<CheckoutRequest> completeCheckout(String checkoutId,
      {int refund = 0, int forfeit = 0}) async {
    final json = await api.post(
        '/checkouts/$checkoutId/complete', {'refund': refund, 'forfeit': forfeit});
    return CheckoutRequest.fromJson(json['checkout'] as Map<String, dynamic>);
  }

  // ── Chat ───────────────────────────────────────────────────────────────
  @override
  Future<List<ChatMessage>> listMessages(String inmateId) async {
    final json = await api.get('/chat?inmate_id=$inmateId');
    return (json['messages'] as List<dynamic>? ?? const [])
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String inmateId,
    required String senderId,
    required String senderRole,
    required String text,
  }) async {
    final json = await api.post('/chat', {
      'inmate_id': inmateId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'text': text,
    });
    return ChatMessage.fromJson(json['message'] as Map<String, dynamic>);
  }

  // ── Expenses & P&L ─────────────────────────────────────────────────────
  @override
  Future<List<Expense>> listExpenses(String propertyId) async {
    final json = await api.get('/expenses?property_id=$propertyId');
    return (json['expenses'] as List<dynamic>? ?? const [])
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Expense> createExpense(Expense expense) async {
    final json = await api.post('/expenses', expense.toJson());
    return Expense.fromJson(json['expense'] as Map<String, dynamic>);
  }

  @override
  Future<Pnl> getPnl(String propertyId) async {
    final json = await api.get('/pnl?property_id=$propertyId');
    return Pnl.fromJson(json['pnl'] as Map<String, dynamic>);
  }

  // ── Ratings ────────────────────────────────────────────────────────────
  @override
  Future<List<Rating>> listRatings(String propertyId) async {
    final json = await api.get('/ratings?property_id=$propertyId');
    return (json['ratings'] as List<dynamic>? ?? const [])
        .map((e) => Rating.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Rating> createRating(Rating rating) async {
    final json = await api.post('/ratings', rating.toJson());
    return Rating.fromJson(json['rating'] as Map<String, dynamic>);
  }

  // ── SOS ────────────────────────────────────────────────────────────────
  @override
  Future<List<SosAlert>> listSos(String propertyId) async {
    final json = await api.get('/sos?property_id=$propertyId');
    return (json['sos'] as List<dynamic>? ?? const [])
        .map((e) => SosAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SosAlert> createSos(SosAlert alert) async {
    final json = await api.post('/sos', alert.toJson());
    return SosAlert.fromJson(json['alert'] as Map<String, dynamic>);
  }

  @override
  Future<SosAlert> acknowledgeSos(String alertId) async {
    final json = await api.post('/sos/$alertId/acknowledge');
    return SosAlert.fromJson(json['alert'] as Map<String, dynamic>);
  }

  // ── Document vault ─────────────────────────────────────────────────────
  @override
  Future<List<Document>> listDocuments(
      String ownerType, String ownerId) async {
    final json =
        await api.get('/documents?owner_type=$ownerType&owner_id=$ownerId');
    return (json['documents'] as List<dynamic>? ?? const [])
        .map((e) => Document.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Document> createDocument(Document document) async {
    final json = await api.post('/documents', document.toJson());
    return Document.fromJson(json['document'] as Map<String, dynamic>);
  }

  @override
  Future<Document> updateDocument(String documentId,
      {String? name, String? type}) async {
    final json = await api.patch('/documents/$documentId', {
      'name': ?name,
      'type': ?type,
    });
    return Document.fromJson(json['document'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    await api.delete('/documents/$documentId');
  }
}

class LocalAdminRepository implements AdminRepository {
  final LocalApiClient api;
  LocalAdminRepository(this.api);

  PricingConfig _parse(Map<String, dynamic> json) =>
      PricingConfig.fromJson(json['pricing'] as Map<String, dynamic>);

  @override
  Future<PricingConfig> getPricing() async => _parse(await api.get('/pricing'));

  @override
  Future<PricingConfig> updatePricing(Pricing pricing) async =>
      _parse(await api.patch('/pricing', pricing.toJson()));

  @override
  Future<PricingConfig> setOverride(String ownerId, Pricing? pricing) async =>
      _parse(await api.patch('/pricing/overrides/$ownerId',
          pricing == null ? {'clear': true} : pricing.toJson()));

  @override
  Future<List<User>> listOwners() async {
    final json = await api.get('/owners');
    return (json['owners'] as List<dynamic>? ?? const [])
        .map((e) => User.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
