import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/theme/app_colors.dart';
import '../../data/backend_provider.dart';
import '../../data/models/inmate.dart';
import '../../data/models/property.dart';
import '../../data/models/room.dart';
import '../../presentation/widgets/glass.dart';
import '../onboarding/hostel_providers.dart';
import '../rent/rent_providers.dart';
import '../ops/ops_providers.dart';
import 'invoice_pdf.dart';

/// Full live profile of one inmate: personal details, stay dates, deposit,
/// payment history, complaints and leave — everything in one place.
class InmateDetailScreen extends ConsumerWidget {
  final String inmateId;
  const InmateDetailScreen({super.key, required this.inmateId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propAsync = ref.watch(currentPropertyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inmate details'),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: GlassBackground(
        dark: isDark,
        child: SafeArea(
          child: propAsync.when(
            data: (prop) => prop == null
                ? Center(child: Text('No property', style: textTheme.bodyMedium))
                : _content(context, ref, prop, textTheme),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const Center(child: Text('Error')),
          ),
        ),
      ),
    );
  }

  Widget _content(
      BuildContext context, WidgetRef ref, Property prop, TextTheme textTheme) {
    final inmates =
        ref.watch(inmatesProvider(prop.id)).value ?? const <Inmate>[];
    Inmate? inmate;
    for (final i in inmates) {
      if (i.id == inmateId) {
        inmate = i;
        break;
      }
    }
    if (inmate == null) {
      return Center(child: Text('Inmate not found', style: textTheme.bodyMedium));
    }

    final payments =
        ref.watch(paymentsProvider(inmateId)).value ?? const [];
    final complaints =
        ref.watch(inmateComplaintsProvider(inmateId)).value ?? const [];
    final leave =
        ref.watch(inmateLeaveProvider(inmateId)).value ?? const [];
    final deposit = ref.watch(inmateDepositProvider(inmateId)).value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        _profileCard(context, inmate, textTheme),
        const SizedBox(height: 12),
        _actionsCard(context, ref, inmate, prop, textTheme),
        const SizedBox(height: 12),
        _stayCard(context, inmate, textTheme),
        if (deposit != null) ...[
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Security deposit', style: textTheme.titleMedium),
                const SizedBox(height: 8),
                _row(context, 'Refundable', '₹${deposit.refundable}'),
                _row(context, 'Deducted', '₹${deposit.deductionsTotal}'),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _header(context, 'Payment history'),
        if (payments.isEmpty)
          _empty(context, 'No payments yet.')
        else
          for (final p in payments) _paymentRow(context, p),
        const SizedBox(height: 16),
        _header(context, 'Complaints'),
        if (complaints.isEmpty)
          _empty(context, 'No complaints.')
        else
          for (final c in complaints) _complaintRow(context, c),
        const SizedBox(height: 16),
        _header(context, 'Leave'),
        if (leave.isEmpty)
          _empty(context, 'No leave records.')
        else
          for (final l in leave) _leaveRow(context, l),
      ],
    );
  }

  Widget _profileCard(BuildContext context, Inmate i, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.16),
                ),
                child: Icon(Icons.person_rounded, size: 28, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.name, style: textTheme.titleLarge),
                    if (i.phone.isNotEmpty)
                      Text(i.phone, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _row(context, 'Room / bed',
              i.roomNo.isNotEmpty ? 'Room ${i.roomNo} · Bed ${i.bedNo}' : 'Tenant'),
          _row(context, 'Rent', '₹${i.rentAmount}/mo · due day ${i.dueDay}'),
          if (i.email.isNotEmpty) _row(context, 'Email', i.email),
          if (i.username.isNotEmpty) _row(context, 'Username', i.username),
        ],
      ),
    );
  }

  Widget _stayCard(BuildContext context, Inmate i, TextTheme textTheme) {
    final checkedOut = i.checkoutDate != null;
    final accent = checkedOut ? AppColors.warning : AppColors.accent;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text('Stay', style: textTheme.titleMedium),
              const Spacer(),
              Text(checkedOut ? 'Checked out' : 'Current resident',
                  style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          _row(context, 'Joined', i.joinDate ?? '—'),
          _row(context, 'Checked out', i.checkoutDate ?? '—'),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _empty(BuildContext context, String msg) =>
      Text(msg, style: Theme.of(context).textTheme.bodySmall);

  Widget _paymentRow(BuildContext context, p) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = p.status.name == 'paid'
        ? AppColors.accent
        : AppColors.warning;
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('₹${p.amount}', style: textTheme.titleMedium),
                Text(
                  p.paidDate != null
                      ? 'Paid ${p.paidDate!.toIso8601String().substring(0, 10)}'
                      : 'Pending',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(p.status.name,
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _complaintRow(BuildContext context, c) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.category, style: textTheme.titleMedium),
                ),
                Text(c.status,
                    style: TextStyle(
                        color: c.status == 'resolved'
                            ? AppColors.accent
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(c.description, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _leaveRow(BuildContext context, l) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${l.startDate} → ${l.endDate}',
                style: textTheme.bodyMedium,
              ),
            ),
            if (l.reason.isNotEmpty)
              Text(l.reason, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodySmall),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }

  // ── Actions: change room, invoice PDF, email invoice ────────────────────
  Widget _actionsCard(BuildContext context, WidgetRef ref, Inmate i,
      Property prop, TextTheme textTheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? AppColors.primaryDark : AppColors.primary;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (prop.isHostelOrPg) ...[
            GlassButton(
              label: 'Change room',
              icon: Icons.meeting_room_rounded,
              color: primary.withValues(alpha: 0.85),
              onPressed: () => _changeRoom(context, ref, i, prop),
            ),
            const SizedBox(height: 10),
          ],
          GlassButton(
            label: 'Generate invoice PDF',
            icon: Icons.picture_as_pdf_rounded,
            onPressed: () => _shareInvoice(context, ref, i),
          ),
          const SizedBox(height: 10),
          GlassButton(
            label: 'Email invoice',
            icon: Icons.email_rounded,
            onPressed: () => _emailInvoice(context, ref, i),
          ),
        ],
      ),
    );
  }

  Future<void> _shareInvoice(BuildContext context, WidgetRef ref, Inmate i) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final invoice =
          await ref.read(backendProvider).inmates.getInvoice(i.id);
      final doc = buildInvoicePdf(invoice);
      await Printing.sharePdf(
          bytes: await doc.save(),
          filename: 'invoice-${invoice['invoice_no']}.pdf');
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not generate invoice: $e')));
    }
  }

  Future<void> _emailInvoice(BuildContext context, WidgetRef ref, Inmate i) async {
    final messenger = ScaffoldMessenger.of(context);
    if (i.email.isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('This inmate has no email on file')));
      return;
    }
    try {
      final res =
          await ref.read(backendProvider).inmates.emailInvoice(i.id);
      messenger.showSnackBar(
          SnackBar(content: Text('Invoice emailed to ${res['to']}')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not email invoice: $e')));
    }
  }

  Future<void> _changeRoom(
      BuildContext context, WidgetRef ref, Inmate i, Property prop) async {
    final messenger = ScaffoldMessenger.of(context);
    final rooms = ref.read(roomsProvider(prop.id)).value ?? const <Room>[];
    final inmates =
        ref.read(inmatesProvider(prop.id)).value ?? const <Inmate>[];
    if (rooms.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No rooms available')));
      return;
    }
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Move to room'),
        children: [
          for (final r in rooms)
            Builder(builder: (_) {
              final count = inmates
                  .where((x) => x.roomId == r.id && x.id != i.id)
                  .length;
              final full = count >= r.capacity;
              return ListTile(
                leading: const Icon(Icons.meeting_room_rounded),
                title: Text('Room ${r.roomNo}'),
                subtitle: Text('$count/${r.capacity} occupied'),
                enabled: !full,
                onTap: () => Navigator.of(ctx).pop(r.id),
              );
            }),
        ],
      ),
    );
    if (choice == null) return;
    final room = rooms.firstWhere((r) => r.id == choice);
    final bed = _firstFreeBed(choice, inmates, room.capacity, i.id);
    if (bed == 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Room is full')));
      return;
    }
    try {
      await ref
          .read(backendProvider)
          .inmates
          .changeRoom(i.id, roomId: choice, bedNo: bed);
      ref.invalidate(inmatesProvider(prop.id));
      messenger.showSnackBar(SnackBar(
          content: Text('Moved to Room ${room.roomNo}, bed $bed')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not change room: $e')));
    }
  }

  int _firstFreeBed(
      String roomId, List<Inmate> inmates, int capacity, String excludeId) {
    for (var b = 1; b <= capacity; b++) {
      final taken = inmates
          .any((x) => x.roomId == roomId && x.bedNo == b && x.id != excludeId);
      if (!taken) return b;
    }
    return 0;
  }
}
