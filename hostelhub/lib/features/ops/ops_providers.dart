import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/backend_provider.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/checkout_request.dart';
import '../../data/models/complaint.dart';
import '../../data/models/deposit.dart';
import '../../data/models/document.dart';
import '../../data/models/expense.dart';
import '../../data/models/leave_record.dart';
import '../../data/models/notice.dart';
import '../../data/models/rating.dart';
import '../../data/models/sos_alert.dart';
import '../../data/models/visitor.dart';

final complaintsProvider = FutureProvider.family<List<Complaint>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listComplaints(propertyId));

final inmateComplaintsProvider =
    FutureProvider.family<List<Complaint>, String>((ref, inmateId) =>
        ref.watch(backendProvider).ops.listInmateComplaints(inmateId));

final noticesProvider = FutureProvider.family<List<Notice>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listNotices(propertyId));

final visitorsProvider = FutureProvider.family<List<Visitor>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listVisitors(propertyId));

final leaveProvider = FutureProvider.family<List<LeaveRecord>, String>(
    (ref, propertyId) => ref.watch(backendProvider).ops.listLeave(propertyId));

final inmateLeaveProvider = FutureProvider.family<List<LeaveRecord>, String>(
    (ref, inmateId) =>
        ref.watch(backendProvider).ops.listInmateLeave(inmateId));

final depositsProvider = FutureProvider.family<List<Deposit>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listDeposits(propertyId));

final inmateDepositProvider = FutureProvider.family<Deposit?, String>(
    (ref, inmateId) =>
        ref.watch(backendProvider).ops.getInmateDeposit(inmateId));

final checkoutsProvider =
    FutureProvider.family<List<CheckoutRequest>, String>((ref, propertyId) =>
        ref.watch(backendProvider).ops.listCheckouts(propertyId));

final chatMessagesProvider = FutureProvider.family<List<ChatMessage>, String>(
    (ref, inmateId) => ref.watch(backendProvider).ops.listMessages(inmateId));

final expensesProvider = FutureProvider.family<List<Expense>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listExpenses(propertyId));

final pnlProvider = FutureProvider.family<Pnl, String>(
    (ref, propertyId) => ref.watch(backendProvider).ops.getPnl(propertyId));

final ratingsProvider = FutureProvider.family<List<Rating>, String>(
    (ref, propertyId) =>
        ref.watch(backendProvider).ops.listRatings(propertyId));

final sosProvider = FutureProvider.family<List<SosAlert>, String>(
    (ref, propertyId) => ref.watch(backendProvider).ops.listSos(propertyId));

final documentsProvider =
    FutureProvider.family<List<Document>, (String, String)>((ref, args) =>
        ref.watch(backendProvider).ops.listDocuments(args.$1, args.$2));
