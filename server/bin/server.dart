import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

/// HostelHub local test backend.
///
/// In-memory store that resets on restart. Mirrors the JSON contract the
/// Supabase/Firebase implementations will expose, so the Flutter app can be
/// tested end-to-end over the LAN before any cloud backend is configured.
///
/// Run:  dart run bin/server.dart
/// Then point the app at http://<LAN-IP>:8080 via --dart-define=LOCAL_BASE_URL.

final Map<String, Map<String, dynamic>> _users = {};
final List<Map<String, dynamic>> _properties = [];
final List<Map<String, dynamic>> _polls = [];
final List<Map<String, dynamic>> _responses = [];
final List<Map<String, dynamic>> _rooms = [];
final List<Map<String, dynamic>> _inmates = [];
final List<Map<String, dynamic>> _payments = [];
final List<Map<String, dynamic>> _complaints = [];
final List<Map<String, dynamic>> _notices = [];
final List<Map<String, dynamic>> _visitors = [];
final List<Map<String, dynamic>> _leave = [];
final List<Map<String, dynamic>> _deposits = [];
final List<Map<String, dynamic>> _checkouts = [];
final List<Map<String, dynamic>> _chat = [];
final List<Map<String, dynamic>> _expenses = [];
final List<Map<String, dynamic>> _ratings = [];
final List<Map<String, dynamic>> _sos = [];
final List<Map<String, dynamic>> _documents = [];
int _seq = 0;
String _nextId(String prefix) => '$prefix-${++_seq}';

String _genUsername(String name) {
  final base = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return '${base.isEmpty ? 'user' : base}${100 + _seq % 900}';
}

String _genPassword() {
  final n = 100000 + (_seq * 7919) % 900000; // pseudo-random 6 digits
  return 'hh$n';
}

/// Returns a copy of a user map without the `password` field (never send it
/// back to the client, even on the local stub).
Map<String, dynamic> _publicUser(Map<String, dynamic> u) =>
    Map<String, dynamic>.of(u)..remove('password');

String _inmateName(String id) {
  for (final i in _inmates) {
    if (i['id'] == id) return i['name'] as String;
  }
  return 'Unknown';
}

Map<String, dynamic>? _inmateById(String id) {
  for (final i in _inmates) {
    if (i['id'] == id) return i;
  }
  return null;
}

Map<String, dynamic>? _findById(List<Map<String, dynamic>> list, String id) {
  for (final m in list) {
    if (m['id'] == id) return m;
  }
  return null;
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

Middleware _cors() => (Handler inner) => (Request req) async {
      if (req.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }
      final res = await inner(req);
      return res.change(headers: _corsHeaders);
    };

Response _json(Object? data, [int status = 200]) => Response(
      status,
      body: jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );

Future<Map<String, dynamic>> _body(Request req) async {
  final raw = await req.readAsString();
  return raw.isEmpty ? {} : jsonDecode(raw) as Map<String, dynamic>;
}

Router _router() {
  final router = Router();

  router.get('/health', (Request req) => _json({'status': 'ok'}));

  // ── Auth ──────────────────────────────────────────────────────────────
  router.post('/auth/register', (Request req) async {
    final body = await _body(req);
    final username = body['username'] as String;
    final user = <String, dynamic>{
      'id': _nextId('user'),
      'role': body['role'] ?? 'owner',
      'property_id': body['property_id'],
      'name': body['name'] ?? '',
      'phone': body['phone'] ?? '',
      'username': username,
      'kyc_verified': false,
      'password': body['password'], // local-only; real auth is Supabase/Firebase
    };
    _users[user['id'] as String] = user;
    return _json(
        {'token': 'local-token-${user['id']}', 'user': _publicUser(user)}, 201);
  });

  router.post('/auth/login', (Request req) async {
    final body = await _body(req);
    final username = body['username'] as String;
    final password = body['password'] as String? ?? '';
    Map<String, dynamic>? found;
    for (final u in _users.values) {
      if (u['username'] == username) found = u;
    }
    if (found == null) {
      return _json({'error': 'invalid credentials'}, 401);
    }
    // Verify password when one is stored (registered users + onboarded inmates).
    final stored = found['password'];
    if (stored != null && stored != password) {
      return _json({'error': 'invalid credentials'}, 401);
    }
    return _json(
        {'token': 'local-token-${found['id']}', 'user': _publicUser(found)}, 200);
  });

  // ── Properties ────────────────────────────────────────────────────────
  router.get('/properties', (Request req) {
    final ownerId = req.url.queryParameters['owner_id'];
    final list = _properties
        .where((p) => ownerId == null || p['owner_id'] == ownerId)
        .toList();
    return _json({'properties': list});
  });

  router.post('/properties', (Request req) async {
    final body = await _body(req);
    final property = <String, dynamic>{
      'id': _nextId('prop'),
      'owner_id': body['owner_id'],
      'name': body['name'],
      'address': body['address'],
      'rent_slabs': body['rent_slabs'] ?? const [],
      'mess_charges': body['mess_charges'] ?? const {},
    };
    _properties.add(property);
    return _json({'property': property}, 201);
  });

  // ── Polls ─────────────────────────────────────────────────────────────
  router.get('/polls', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _polls
        .where((p) => propertyId == null || p['property_id'] == propertyId)
        .toList();
    return _json({'polls': list});
  });

  router.post('/polls', (Request req) async {
    final body = await _body(req);
    final poll = <String, dynamic>{
      'id': _nextId('poll'),
      'property_id': body['property_id'],
      'meal_type': body['meal_type'],
      'for_date': body['for_date'],
      'send_at': body['send_at'],
      'close_at': body['close_at'],
      'recurring': body['recurring'] ?? false,
      'options': body['options'] ?? const ['Yes', 'No'],
    };
    _polls.add(poll);
    return _json({'poll': poll}, 201);
  });

  router.post('/polls/<pollId>/respond', (Request req, String pollId) async {
    final body = await _body(req);
    final response = <String, dynamic>{
      'id': _nextId('resp'),
      'poll_id': pollId,
      'inmate_id': body['inmate_id'],
      'response': body['response'],
      'responded_at': DateTime.now().toIso8601String(),
    };
    _responses.add(response);
    return _json({'response': response}, 201);
  });

  router.get('/polls/<pollId>/responses', (Request req, String pollId) {
    final list = _responses.where((r) => r['poll_id'] == pollId).toList();
    return _json({'responses': list});
  });

  // ── Rooms ─────────────────────────────────────────────────────────────
  router.get('/rooms', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _rooms
        .where((r) => propertyId == null || r['property_id'] == propertyId)
        .toList();
    return _json({'rooms': list});
  });

  router.post('/rooms', (Request req) async {
    final body = await _body(req);
    final room = <String, dynamic>{
      'id': _nextId('room'),
      'property_id': body['property_id'],
      'room_no': body['room_no'],
      'capacity': body['capacity'] ?? 1,
    };
    _rooms.add(room);
    return _json({'room': room}, 201);
  });

  // ── Inmates ───────────────────────────────────────────────────────────
  router.get('/inmates', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _inmates
        .where((i) => propertyId == null || i['property_id'] == propertyId)
        .toList();
    return _json({'inmates': list});
  });

  router.post('/inmates', (Request req) async {
    final body = await _body(req);
    final name = body['name'] as String;
    final roomId = body['room_id'] as String;
    final room = _rooms.firstWhere((r) => r['id'] == roomId,
        orElse: () => {'room_no': '?'});
    final id = _nextId('user');
    final username = _genUsername(name);
    final password = _genPassword();
    final inmate = <String, dynamic>{
      'id': id,
      'property_id': body['property_id'],
      'name': name,
      'phone': body['phone'] ?? '',
      'username': username,
      'room_id': roomId,
      'room_no': room['room_no'],
      'bed_no': body['bed_no'] ?? 1,
      'rent_amount': body['rent_amount'] ?? 0,
      'due_day': body['due_day'] ?? 1,
      'join_date': body['join_date'],
      'kyc_verified': false,
    };
    _inmates.add(inmate);
    // Register a login so the inmate can sign in with the generated password.
    _users[id] = {
      'id': id,
      'role': 'inmate',
      'property_id': body['property_id'],
      'name': name,
      'phone': body['phone'] ?? '',
      'username': username,
      'kyc_verified': false,
      'password': password,
    };
    return _json({'inmate': inmate, 'password': password}, 201);
  });

  // ── Rent plans (derived from inmate rent terms) ─────────────────────────
  router.get('/rent-plans', (Request req) {
    final inmateId = req.url.queryParameters['inmate_id'];
    final inmate = _inmates.where((i) => i['id'] == inmateId).firstOrNull;
    if (inmate == null) return _json({'rent_plan': null});
    final plan = <String, dynamic>{
      'id': 'rp-$inmateId',
      'inmate_id': inmateId,
      'amount': inmate['rent_amount'] ?? 0,
      'due_day': inmate['due_day'] ?? 1,
      'grace_days': 3,
      'late_fee_rule': 'flat:100',
      'autopay_enabled': false,
      'mandate_id': null,
    };
    return _json({'rent_plan': plan});
  });

  // ── Payments ───────────────────────────────────────────────────────────
  router.get('/payments', (Request req) {
    final inmateId = req.url.queryParameters['inmate_id'];
    final list = _payments
        .where((p) => inmateId == null || p['inmate_id'] == inmateId)
        .toList();
    return _json({'payments': list});
  });

  router.post('/payments', (Request req) async {
    final body = await _body(req);
    final id = _nextId('pay');
    // Local test: the UPI charge is simulated as immediately successful.
    final payment = <String, dynamic>{
      'id': id,
      'inmate_id': body['inmate_id'],
      'property_id': _inmateById(body['inmate_id'] as String)?['property_id'],
      'amount': body['amount'],
      'due_date': body['due_date'],
      'paid_date': DateTime.now().toIso8601String(),
      'status': 'paid',
      'method': 'upi',
      'receipt_url': 'receipt-$id',
    };
    _payments.add(payment);
    return _json({'payment': payment}, 201);
  });

  // ── Complaints ────────────────────────────────────────────────────────
  router.get('/complaints', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final inmateId = req.url.queryParameters['inmate_id'];
    final list = _complaints
        .where((c) =>
            (propertyId == null || c['property_id'] == propertyId) &&
            (inmateId == null || c['inmate_id'] == inmateId))
        .toList();
    return _json({'complaints': list});
  });

  router.post('/complaints', (Request req) async {
    final body = await _body(req);
    final complaint = <String, dynamic>{
      'id': _nextId('complaint'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'category': body['category'],
      'description': body['description'] ?? '',
      'status': 'open',
      'created_at': DateTime.now().toIso8601String(),
    };
    _complaints.add(complaint);
    return _json({'complaint': complaint}, 201);
  });

  router.post('/complaints/<id>/status', (Request req, String id) async {
    final body = await _body(req);
    final c = _findById(_complaints, id);
    if (c == null) return _json({'error': 'not found'}, 404);
    c['status'] = body['status'];
    return _json({'complaint': c});
  });

  // ── Notices ───────────────────────────────────────────────────────────
  router.get('/notices', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _notices
        .where((n) => propertyId == null || n['property_id'] == propertyId)
        .toList();
    return _json({'notices': list});
  });

  router.post('/notices', (Request req) async {
    final body = await _body(req);
    final notice = <String, dynamic>{
      'id': _nextId('notice'),
      'property_id': body['property_id'],
      'title': body['title'],
      'body': body['body'] ?? '',
      'category': body['category'] ?? 'general',
      'pinned': body['pinned'] ?? false,
      'created_at': DateTime.now().toIso8601String(),
    };
    _notices.add(notice);
    return _json({'notice': notice}, 201);
  });

  // ── Visitors ──────────────────────────────────────────────────────────
  router.get('/visitors', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _visitors
        .where((v) => propertyId == null || v['property_id'] == propertyId)
        .toList();
    return _json({'visitors': list});
  });

  router.post('/visitors', (Request req) async {
    final body = await _body(req);
    final visitor = <String, dynamic>{
      'id': _nextId('visitor'),
      'property_id': body['property_id'],
      'name': body['name'],
      'phone': body['phone'] ?? '',
      'purpose': body['purpose'] ?? '',
      'visiting_inmate_name': body['visiting_inmate_name'] ?? '',
      'in_time': DateTime.now().toIso8601String(),
      'out_time': null,
    };
    _visitors.add(visitor);
    return _json({'visitor': visitor}, 201);
  });

  router.post('/visitors/<id>/checkout', (Request req, String id) async {
    final v = _findById(_visitors, id);
    if (v == null) return _json({'error': 'not found'}, 404);
    v['out_time'] = DateTime.now().toIso8601String();
    return _json({'visitor': v});
  });

  // ── Leave ─────────────────────────────────────────────────────────────
  router.get('/leave', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final inmateId = req.url.queryParameters['inmate_id'];
    final list = _leave
        .where((l) =>
            (propertyId == null || l['property_id'] == propertyId) &&
            (inmateId == null || l['inmate_id'] == inmateId))
        .toList();
    return _json({'leave': list});
  });

  router.post('/leave', (Request req) async {
    final body = await _body(req);
    final record = <String, dynamic>{
      'id': _nextId('leave'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'start_date': body['start_date'],
      'end_date': body['end_date'],
      'reason': body['reason'] ?? '',
      'status': 'on_leave',
    };
    _leave.add(record);
    return _json({'record': record}, 201);
  });

  // ── Deposits ──────────────────────────────────────────────────────────
  router.get('/deposits', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final inmateId = req.url.queryParameters['inmate_id'];
    final list = _deposits
        .where((d) =>
            (propertyId == null || d['property_id'] == propertyId) &&
            (inmateId == null || d['inmate_id'] == inmateId))
        .toList();
    return _json({'deposits': list});
  });

  router.post('/deposits', (Request req) async {
    final body = await _body(req);
    final deposit = <String, dynamic>{
      'id': _nextId('deposit'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'amount_collected': body['amount_collected'] ?? 0,
      'deductions': [],
      'status': 'held',
    };
    _deposits.add(deposit);
    return _json({'deposit': deposit}, 201);
  });

  router.post('/deposits/<id>/deduct', (Request req, String id) async {
    final body = await _body(req);
    final d = _findById(_deposits, id);
    if (d == null) return _json({'error': 'not found'}, 404);
    (d['deductions'] as List)
        .add({'reason': body['reason'], 'amount': body['amount']});
    return _json({'deposit': d});
  });

  // ── Checkout ──────────────────────────────────────────────────────────
  router.get('/checkouts', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _checkouts
        .where((c) => propertyId == null || c['property_id'] == propertyId)
        .toList();
    return _json({'checkouts': list});
  });

  router.post('/checkouts', (Request req) async {
    final body = await _body(req);
    final request = <String, dynamic>{
      'id': _nextId('checkout'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'vacate_date': body['vacate_date'],
      'status': 'requested',
    };
    _checkouts.add(request);
    return _json({'checkout': request}, 201);
  });

  // ── Chat ───────────────────────────────────────────────────────────────
  router.get('/chat', (Request req) {
    final inmateId = req.url.queryParameters['inmate_id'];
    final list = _chat.where((m) => m['inmate_id'] == inmateId).toList();
    return _json({'messages': list});
  });

  router.post('/chat', (Request req) async {
    final body = await _body(req);
    final msg = <String, dynamic>{
      'id': _nextId('msg'),
      'inmate_id': body['inmate_id'],
      'sender_id': body['sender_id'],
      'sender_role': body['sender_role'],
      'text': body['text'],
      'sent_at': DateTime.now().toIso8601String(),
    };
    _chat.add(msg);
    return _json({'message': msg}, 201);
  });

  // ── Expenses & P&L ─────────────────────────────────────────────────────
  router.get('/expenses', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _expenses
        .where((e) => propertyId == null || e['property_id'] == propertyId)
        .toList();
    return _json({'expenses': list});
  });

  router.post('/expenses', (Request req) async {
    final body = await _body(req);
    final expense = <String, dynamic>{
      'id': _nextId('expense'),
      'property_id': body['property_id'],
      'category': body['category'],
      'amount': body['amount'],
      'date': body['date'] ?? DateTime.now().toIso8601String().substring(0, 10),
      'notes': body['notes'] ?? '',
    };
    _expenses.add(expense);
    return _json({'expense': expense}, 201);
  });

  router.get('/pnl', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    var income = 0;
    for (final p in _payments) {
      if (p['property_id'] == propertyId && p['status'] == 'paid') {
        income += p['amount'] as int;
      }
    }
    final byCategory = <String, int>{};
    var expense = 0;
    for (final e in _expenses) {
      if (e['property_id'] == propertyId) {
        final amount = e['amount'] as int;
        expense += amount;
        byCategory[e['category']] =
            (byCategory[e['category']] ?? 0) + amount;
      }
    }
    return _json({
      'pnl': {
        'income': income,
        'expense': expense,
        'net': income - expense,
        'expense_by_category': byCategory,
      }
    });
  });

  // ── Ratings ────────────────────────────────────────────────────────────
  router.get('/ratings', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _ratings
        .where((r) => propertyId == null || r['property_id'] == propertyId)
        .toList();
    return _json({'ratings': list});
  });

  router.post('/ratings', (Request req) async {
    final body = await _body(req);
    final rating = <String, dynamic>{
      'id': _nextId('rating'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'stars': body['stars'],
      'comment': body['comment'] ?? '',
      'created_at': DateTime.now().toIso8601String(),
    };
    _ratings.add(rating);
    return _json({'rating': rating}, 201);
  });

  // ── SOS ────────────────────────────────────────────────────────────────
  router.get('/sos', (Request req) {
    final propertyId = req.url.queryParameters['property_id'];
    final list = _sos
        .where((s) => propertyId == null || s['property_id'] == propertyId)
        .toList();
    return _json({'sos': list});
  });

  router.post('/sos', (Request req) async {
    final body = await _body(req);
    final alert = <String, dynamic>{
      'id': _nextId('sos'),
      'property_id': body['property_id'],
      'inmate_id': body['inmate_id'],
      'inmate_name': _inmateName(body['inmate_id'] as String),
      'triggered_at': DateTime.now().toIso8601String(),
      'acknowledged': false,
    };
    _sos.add(alert);
    return _json({'alert': alert}, 201);
  });

  router.post('/sos/<id>/acknowledge', (Request req, String id) async {
    final s = _findById(_sos, id);
    if (s == null) return _json({'error': 'not found'}, 404);
    s['acknowledged'] = true;
    return _json({'alert': s});
  });

  // ── Document vault ─────────────────────────────────────────────────────
  router.get('/documents', (Request req) {
    final ownerType = req.url.queryParameters['owner_type'];
    final ownerId = req.url.queryParameters['owner_id'];
    final list = _documents
        .where((d) =>
            (ownerType == null || d['owner_type'] == ownerType) &&
            (ownerId == null || d['owner_id'] == ownerId))
        .toList();
    return _json({'documents': list});
  });

  router.post('/documents', (Request req) async {
    final body = await _body(req);
    final doc = <String, dynamic>{
      'id': _nextId('doc'),
      'owner_type': body['owner_type'],
      'owner_id': body['owner_id'],
      'name': body['name'],
      'type': body['type'] ?? 'other',
      'file_url': body['file_url'],
      'uploaded_at': DateTime.now().toIso8601String(),
    };
    _documents.add(doc);
    return _json({'document': doc}, 201);
  });

  return router;
}

Future<void> main() async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_cors())
      .addHandler(_router().call);

  final port = int.parse(Platform.environment['PORT'] ?? '8081');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('HostelHub local server on port ${server.port}');
  print('Reachable at:');
  for (final iface
      in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
    for (final addr in iface.addresses) {
      print('  http://${addr.address}:${server.port}');
    }
  }
}
