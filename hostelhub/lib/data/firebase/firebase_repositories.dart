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
import '../models/property.dart';
import '../models/rating.dart';
import '../models/rent_plan.dart';
import '../models/room.dart';
import '../models/sos_alert.dart';
import '../models/user.dart';
import '../models/visitor.dart';
import '../repositories/repositories.dart';

/// Firebase (Firestore + Auth) implementations — STUBS.
///
/// Wire these to the Firebase SDK once google-services.json /
/// GoogleService-Info.plist are in place:
///   - auth     → FirebaseAuth.instance.signInWithEmailAndPassword
///   - data     → FirebaseFirestore.instance.collection('properties')...
///   - realtime → snapshot streams on 'polls' / 'chat' collections
/// Tenant isolation is enforced by Firestore security rules (doc §7).
class FirebaseAuthRepository implements AuthRepository {
  @override
  Future<User> login(String username, String password) {
    throw UnimplementedError(
        'Firebase backend not wired — set BACKEND=firebase after adding config');
  }

  @override
  Future<User> register(User user, String password) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<User?> currentUser() async => null;

  @override
  Future<void> logout() async {}
}

class FirebasePropertyRepository implements PropertyRepository {
  @override
  Future<List<Property>> listProperties(String ownerId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Property> createProperty(Property property) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Property> getProperty(String id) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Property> updateProperty(String id,
      {String? type, Map<String, bool>? features}) {
    throw UnimplementedError('Firebase backend not wired');
  }
}

class FirebasePollRepository implements PollRepository {
  @override
  Future<List<Poll>> listPolls(String propertyId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Poll> createPoll(Poll poll) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<PollResponse> respond(PollResponse response) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<List<PollResponse>> listResponses(String pollId) {
    throw UnimplementedError('Firebase backend not wired');
  }
}

class FirebaseRoomRepository implements RoomRepository {
  @override
  Future<List<Room>> listRooms(String propertyId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Room> createRoom(Room room) {
    throw UnimplementedError('Firebase backend not wired');
  }
}

class FirebaseInmateRepository implements InmateRepository {
  @override
  Future<List<Inmate>> listInmates(String propertyId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<NewInmate> createInmate({
    required String propertyId,
    required String name,
    required String phone,
    required String roomId,
    required int bedNo,
    required int rentAmount,
    required int dueDay,
    required String joinDate,
  }) {
    throw UnimplementedError('Firebase backend not wired');
  }
}

class FirebaseRentRepository implements RentRepository {
  @override
  Future<RentPlan?> getRentPlan(String inmateId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<List<Payment>> listPayments(String inmateId) {
    throw UnimplementedError('Firebase backend not wired');
  }

  @override
  Future<Payment> payRent({
    required String inmateId,
    required int amount,
    required String dueDate,
  }) {
    throw UnimplementedError('Firebase backend not wired');
  }
}

class FirebaseOpsRepository implements OpsRepository {
  Never _n() => throw UnimplementedError('Firebase backend not wired');

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
}
