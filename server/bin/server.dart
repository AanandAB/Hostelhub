import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
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
final Map<String, Map<String, dynamic>> _subscriptions = {};
int _seq = 0;
String _nextId(String prefix) => '$prefix-${++_seq}';

/// Subscription stub: each owner gets a default active monthly plan (1 property).
Map<String, dynamic> _ensureSubscription(String ownerId) =>
    _subscriptions.putIfAbsent(
        ownerId,
        () => {
              'plan': 'monthly',
              'status': 'active',
              'property_limit': 1,
              'expires_at': null,
            });

/// Subscription rates (₹) — global plus per-owner overrides, editable from
/// the admin panel.
final Map<String, dynamic> _pricing = {
  'monthly': 599,
  'yearly': 5999,
  'extra_property': 199,
};
final Map<String, Map<String, dynamic>> _pricingOverrides = {};

/// Seed the super-admin account (username: `admin`, password: `admin123`).
void _seedAdmin() {
  _users.putIfAbsent(
      'admin',
      () => {
            'id': 'admin',
            'role': 'admin',
            'property_id': null,
            'name': 'Platform Admin',
            'phone': '',
            'username': 'admin',
            'kyc_verified': false,
            'password': _hashPassword('admin123'),
          });
}

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

// ── Security helpers (OWASP A04/A07) ──────────────────────────────────────
/// Cryptographically secure random source (never `Random` for tokens).
final _rng = Random.secure();

String _randomHex(int bytes) => List.generate(
    bytes, (_) => _rng.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

/// PBKDF2-HMAC-SHA256 (OWASP-recommended password hashing primitive).
List<int> _pbkdf2(List<int> password, List<int> salt, int iterations, int dkLen) {
  final hmac = Hmac(sha256, password);
  final blocks = (dkLen / 32).ceil();
  final out = <int>[];
  for (var i = 1; i <= blocks; i++) {
    var u = hmac
        .convert([...salt, (i >> 24) & 0xff, (i >> 16) & 0xff, (i >> 8) & 0xff, i & 0xff])
        .bytes;
    final t = List<int>.from(u);
    for (var j = 1; j < iterations; j++) {
      u = hmac.convert(u).bytes;
      for (var k = 0; k < t.length; k++) {
        t[k] ^= u[k];
      }
    }
    out.addAll(t);
  }
  return out.sublist(0, dkLen);
}

/// Returns a salted PBKDF2 hash string: `pbkdf2$<iter>$<saltB64>$<hashB64>`.
String _hashPassword(String password) {
  const iterations = 100000;
  final salt = List<int>.generate(16, (_) => _rng.nextInt(256));
  final dk = _pbkdf2(utf8.encode(password), salt, iterations, 32);
  return 'pbkdf2\$$iterations\$${base64.encode(salt)}\$${base64.encode(dk)}';
}

bool _verifyPassword(String password, String stored) {
  final parts = stored.split(r'$');
  if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
  final iterations = int.parse(parts[1]);
  final salt = base64.decode(parts[2]);
  final expected = parts[3];
  final dk = _pbkdf2(utf8.encode(password), salt, iterations, 32);
  return base64.encode(dk) == expected;
}

/// Password-reset tokens: token_hash -> {user_id, expires_at}.
final Map<String, Map<String, dynamic>> _resetTokens = {};

/// Minimal login rate limiter (per IP) — blocks credential stuffing (A07).
/// Production should use edge-level rate limiting (Cloudflare/WAF).
final Map<String, List<DateTime>> _loginAttempts = {};
String _clientIp(Request req) {
  final xff = req.headers['x-forwarded-for'];
  if (xff != null && xff.isNotEmpty) return xff.split(',').first.trim();
  final conn = req.context['shelf.io.connection_info'];
  if (conn is HttpConnectionInfo) return conn.remoteAddress.address;
  return 'unknown';
}
bool _rateLimited(String ip) {
  const window = Duration(minutes: 15);
  const maxAttempts = 10;
  final now = DateTime.now();
  final list = _loginAttempts.putIfAbsent(ip, () => []);
  list.removeWhere((t) => now.difference(t) > window);
  if (list.length >= maxAttempts) return true;
  list.add(now);
  return false;
}

/// Pluggable email transport. Currently a LOG transport (writes each message
/// to `outbox/` + console). To go live, replace this body with SMTP/Resend —
/// the call sites don't change.
Future<void> _sendEmail(
    {required String to, required String subject, required String html}) async {
  final dir = Directory('outbox');
  if (!dir.existsSync()) dir.createSync(recursive: true);
  final safe = to.replaceAll(RegExp(r'[^a-zA-Z0-9@.]'), '_');
  final file = File('outbox/${DateTime.now().millisecondsSinceEpoch}-$safe.html');
  await file.writeAsString('Subject: $subject\nTo: $to\n\n$html');
  print('[email] to=$to subject="$subject" -> ${file.path}');
}

/// Simple server-rendered password-reset page (opened from the emailed link).
String _resetPage() => '''
<!doctype html><html><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Reset password — HostelHub</title>
<style>
 body{font-family:system-ui,sans-serif;max-width:360px;margin:60px auto;padding:0 20px}
 input{width:100%;padding:12px;margin:8px 0;font-size:16px;box-sizing:border-box}
 button{width:100%;padding:12px;font-size:16px;background:#2563eb;color:#fff;border:0;border-radius:8px}
 #msg{margin-top:12px;font-size:14px}
</style></head><body>
<h2>Reset your password</h2>
<p>Choose a new password for your HostelHub account.</p>
<input type="password" id="p1" placeholder="New password" autocomplete="new-password">
<input type="password" id="p2" placeholder="Confirm password" autocomplete="new-password">
<button onclick="doReset()">Reset password</button>
<div id="msg"></div>
<script>
const token = new URLSearchParams(location.search).get('token') || '';
async function doReset(){
  const p1=document.getElementById('p1').value;
  const p2=document.getElementById('p2').value;
  const m=document.getElementById('msg');
  if(p1.length<6){m.textContent='Password must be at least 6 characters';return;}
  if(p1!==p2){m.textContent='Passwords do not match';return;}
  const r=await fetch('/auth/reset-password',{method:'POST',
    headers:{'Content-Type':'application/json'},
    body:JSON.stringify({token,password:p1})});
  const d=await r.json();
  m.textContent=d.ok?'Password reset! You can now log in.':(d.error||'Reset failed.');
}
</script></body></html>''';

/// Next due date based on the inmate's monthly due day.
String _nextDueDate(Map<String, dynamic> inmate, DateTime now) {
  final dueDay = (inmate['due_day'] as int? ?? 1).clamp(1, 28).toInt();
  var d = DateTime(now.year, now.month, dueDay);
  if (!d.isAfter(now)) d = DateTime(now.year, now.month + 1, dueDay);
  return d.toIso8601String().substring(0, 10);
}

/// Builds a structured per-inmate invoice (rent + outstanding dues).
Map<String, dynamic> _buildInvoice(Map<String, dynamic> inmate, {String? month}) {
  final propertyId = inmate['property_id'] as String;
  final property = _findById(_properties, propertyId);
  final now = DateTime.now();
  final period = month ?? '${now.year}-${now.month.toString().padLeft(2, '0')}';
  final invoiceNo = 'INV-${period.replaceAll('-', '')}-${inmate['id']}';
  final rentAmount = (inmate['rent_amount'] as num?)?.toInt() ?? 0;
  var dues = 0;
  for (final p in _payments) {
    if (p['inmate_id'] == inmate['id'] && p['status'] != 'paid') {
      dues += (p['amount'] as num?)?.toInt() ?? 0;
    }
  }
  var depositHeld = 0;
  for (final d in _deposits) {
    if (d['inmate_id'] == inmate['id']) {
      depositHeld += (d['amount_collected'] as num?)?.toInt() ?? 0;
      for (final ded in (d['deductions'] as List? ?? const [])) {
        depositHeld -= ((ded as Map)['amount'] as num?)?.toInt() ?? 0;
      }
    }
  }
  final lineItems = <Map<String, dynamic>>[
    {'description': 'Room rent — $period', 'amount': rentAmount},
    if (dues > 0) {'description': 'Outstanding dues', 'amount': dues},
  ];
  final total = rentAmount + dues;
  return <String, dynamic>{
    'invoice_no': invoiceNo,
    'invoice_date': now.toIso8601String().substring(0, 10),
    'period': period,
    'due_date': _nextDueDate(inmate, now),
    'property': {
      'name': property?['name'] ?? '',
      'address': property?['address'] ?? '',
    },
    'inmate': {
      'name': inmate['name'],
      'email': inmate['email'] ?? '',
      'phone': inmate['phone'] ?? '',
      'room_no': inmate['room_no'] ?? '',
      'bed_no': inmate['bed_no'] ?? 0,
    },
    'line_items': lineItems,
    'subtotal': total,
    'total': total,
    'deposit_held': depositHeld,
    'currency': 'INR',
  };
}

/// HTML email body for an invoice (used by the log transport).
String _invoiceHtml(Map<String, dynamic> inv) {
  final p = inv['property'] as Map;
  final i = inv['inmate'] as Map;
  final roomNo = i['room_no'] ?? '';
  final phone = i['phone'] ?? '';
  final rows = (inv['line_items'] as List)
      .map((li) => '<tr><td style="padding:6px 0">${li['description']}</td>'
          '<td style="text-align:right">₹${li['amount']}</td></tr>')
      .join();
  final roomLine = roomNo.isNotEmpty ? ' — Room $roomNo / Bed ${i['bed_no']}' : '';
  final phoneLine = phone.isNotEmpty ? ' · $phone' : '';
  return '<div style="font-family:sans-serif;max-width:560px;margin:auto">'
      '<h2>${p['name']}</h2><p>${p['address']}</p><hr>'
      '<h3>Invoice ${inv['invoice_no']}</h3>'
      '<p>Date: ${inv['invoice_date']} &nbsp;|&nbsp; Due: ${inv['due_date']}</p>'
      '<p><strong>Billed to:</strong> ${i['name']}$roomLine<br>'
      '${i['email']}$phoneLine</p>'
      '<table width="100%" style="border-collapse:collapse;border-top:1px solid #ddd">'
      '<tr><th align="left" style="padding:6px 0">Description</th><th align="right">Amount</th></tr>'
      '$rows'
      '<tr style="border-top:1px solid #ddd"><td style="padding:6px 0"><strong>Total</strong></td>'
      '<td align="right"><strong>₹${inv['total']}</strong></td></tr>'
      '</table>'
      '<p>Deposit held: ₹${inv['deposit_held']}</p>'
      '<p style="color:#666">Please pay by the due date. Thank you!</p></div>';
}

Router _router() {
  final router = Router();
  _seedAdmin();

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
      'email': body['email'] ?? '',
      'username': username,
      'kyc_verified': false,
      'password': _hashPassword(body['password'] as String? ?? ''),
    };
    _users[user['id'] as String] = user;
    if (user['role'] == 'owner') _ensureSubscription(user['id'] as String);
    return _json(
        {'token': 'local-token-${user['id']}', 'user': _publicUser(user)}, 201);
  });

  router.post('/auth/login', (Request req) async {
    if (_rateLimited(_clientIp(req))) {
      return _json({'error': 'Too many attempts. Try again later.'}, 429);
    }
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
    final stored = found['password'];
    if (stored != null && !_verifyPassword(password, stored as String)) {
      return _json({'error': 'invalid credentials'}, 401);
    }
    if (found['role'] == 'owner') {
      final sub = _ensureSubscription(found['id'] as String);
      if (sub['status'] == 'expired') {
        return _json({'error': 'Subscription expired. Please renew.'}, 403);
      }
    }
    return _json(
        {'token': 'local-token-${found['id']}', 'user': _publicUser(found)}, 200);
  });

  // ── Password reset (email-link, expiring token) ─────────────────────────
  router.post('/auth/forgot-password', (Request req) async {
    if (_rateLimited(_clientIp(req))) {
      return _json({'error': 'Too many attempts. Try again later.'}, 429);
    }
    final body = await _body(req);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    Map<String, dynamic>? user;
    for (final u in _users.values) {
      final ue = (u['email'] as String? ?? '').toLowerCase();
      if (email.isNotEmpty && ue == email) {
        user = u;
        break;
      }
    }
    // Always return success — never reveal whether an email exists (A07).
    if (user == null) return _json({'ok': true});
    final token = _randomHex(32);
    final tokenHash = sha256.convert(utf8.encode(token)).toString();
    _resetTokens[tokenHash] = {
      'user_id': user['id'],
      'expires_at':
          DateTime.now().add(const Duration(minutes: 15)).toIso8601String(),
    };
    final host = req.headers['host'] ?? 'localhost:8081';
    final link = 'http://$host/reset?token=$token';
    await _sendEmail(
      to: email,
      subject: 'Reset your HostelHub password',
      html: '<p>Hi ${user['name'] ?? ''},</p>'
          '<p>Tap the link below to reset your password (valid for 15 minutes):</p>'
          '<p><a href="$link">$link</a></p>'
          "<p>If you didn't request this, you can safely ignore this email.</p>",
    );
    return _json({'ok': true});
  });

  router.post('/auth/reset-password', (Request req) async {
    final body = await _body(req);
    final token = body['token'] as String? ?? '';
    final password = body['password'] as String? ?? '';
    if (password.length < 6) {
      return _json({'error': 'Password must be at least 6 characters'}, 400);
    }
    final tokenHash = sha256.convert(utf8.encode(token)).toString();
    final record = _resetTokens[tokenHash];
    if (record == null) {
      return _json({'error': 'Invalid or expired reset link'}, 400);
    }
    if (DateTime.now().isAfter(DateTime.parse(record['expires_at'] as String))) {
      _resetTokens.remove(tokenHash);
      return _json({'error': 'Reset link has expired'}, 400);
    }
    final user = _users[record['user_id'] as String];
    if (user != null) user['password'] = _hashPassword(password);
    _resetTokens.remove(tokenHash); // single-use
    return _json({'ok': true});
  });

  // Simple browser page opened from the emailed reset link.
  router.get('/reset', (Request req) => Response.ok(
      _resetPage(),
      headers: {'Content-Type': 'text/html; charset=utf-8'}));

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
    // Subscription enforcement: active plan + property-count limit.
    final ownerId = body['owner_id'] as String;
    final sub = _ensureSubscription(ownerId);
    if (sub['status'] == 'expired') {
      return _json({'error': 'Subscription expired. Please renew.'}, 403);
    }
    final limit = sub['property_limit'] as int? ?? 1;
    final count = _properties.where((p) => p['owner_id'] == ownerId).length;
    if (count >= limit) {
      return _json(
          {'error': 'Property limit reached ($count/$limit). Upgrade to add more.'},
          403);
    }
    final type = body['type'] as String? ?? 'hostel';
    final features = <String, bool>{
      'rent': true,
      // Mess/polls default ON for hostel & PG, OFF for house/office.
      'mess': type == 'hostel' || type == 'pg',
      'complaints': true,
      'notices': true,
      'leave': true,
      'deposits': true,
      'chat': true,
      'ratings': true,
      'sos': true,
      'documents': true,
    };
    final bodyFeatures = body['features'];
    if (bodyFeatures is Map) {
      bodyFeatures.forEach((k, v) => features[k.toString()] = v == true);
    }
    final property = <String, dynamic>{
      'id': _nextId('prop'),
      'owner_id': body['owner_id'],
      'name': body['name'],
      'address': body['address'],
      'type': type,
      'features': features,
      'rent_amount': body['rent_amount'] ?? 0,
      'rent_slabs': body['rent_slabs'] ?? const [],
      'mess_charges': body['mess_charges'] ?? const {},
    };
    _properties.add(property);
    return _json({'property': property}, 201);
  });

  router.get('/properties/<id>', (Request req, String id) {
    final p = _findById(_properties, id);
    if (p == null) return _json({'error': 'not found'}, 404);
    return _json({'property': p});
  });

  router.patch('/properties/<id>', (Request req, String id) async {
    final body = await _body(req);
    final p = _findById(_properties, id);
    if (p == null) return _json({'error': 'not found'}, 404);
    if (body['type'] != null) p['type'] = body['type'];
    final bodyFeatures = body['features'];
    if (bodyFeatures is Map) {
      final f = p['features'] as Map? ?? <String, dynamic>{};
      bodyFeatures.forEach((k, v) => f[k.toString()] = v == true);
      p['features'] = f;
    }
    return _json({'property': p});
  });

  // ── Subscriptions (stub) ──────────────────────────────────────────────
  router.get('/subscriptions/<ownerId>', (Request req, String ownerId) {
    return _json({'subscription': _ensureSubscription(ownerId)});
  });

  router.post('/subscriptions/<ownerId>/expire', (Request req, String ownerId) {
    final sub = _ensureSubscription(ownerId);
    sub['status'] = 'expired';
    return _json({'subscription': sub});
  });

  router.post('/subscriptions/<ownerId>/renew', (Request req, String ownerId) {
    final sub = _ensureSubscription(ownerId);
    sub['status'] = 'active';
    return _json({'subscription': sub});
  });

  router.post('/subscriptions/<ownerId>/upgrade', (Request req, String ownerId) {
    final sub = _ensureSubscription(ownerId);
    sub['property_limit'] = (sub['property_limit'] as int? ?? 1) + 1;
    return _json({'subscription': sub});
  });

  // ── Admin: pricing + clients ──────────────────────────────────────────
  router.get('/pricing', (Request req) {
    return _json({
      'pricing': {'global': _pricing, 'overrides': _pricingOverrides}
    });
  });

  router.patch('/pricing', (Request req) async {
    final body = await _body(req);
    if (body['monthly'] is num) _pricing['monthly'] = body['monthly'];
    if (body['yearly'] is num) _pricing['yearly'] = body['yearly'];
    if (body['extra_property'] is num) {
      _pricing['extra_property'] = body['extra_property'];
    }
    return _json({
      'pricing': {'global': _pricing, 'overrides': _pricingOverrides}
    });
  });

  router.patch('/pricing/overrides/<ownerId>',
      (Request req, String ownerId) async {
    final body = await _body(req);
    if (body['clear'] == true) {
      _pricingOverrides.remove(ownerId);
    } else {
      _pricingOverrides[ownerId] = {
        'monthly': body['monthly'] ?? _pricing['monthly'],
        'yearly': body['yearly'] ?? _pricing['yearly'],
        'extra_property':
            body['extra_property'] ?? _pricing['extra_property'],
      };
    }
    return _json({
      'pricing': {'global': _pricing, 'overrides': _pricingOverrides}
    });
  });

  router.get('/owners', (Request req) {
    final list = _users.values.where((u) => u['role'] == 'owner').toList();
    return _json({'owners': list.map((u) => _publicUser(u)).toList()});
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
    final roomId = body['room_id'] as String? ?? '';
    String roomNo = '';
    int bedNo = 0;
    // Room/bed assignment only applies to room-based properties (hostel/PG).
    // Houses & offices have no rooms — rent is per property.
    if (roomId.isNotEmpty) {
      final room = _rooms.firstWhere((r) => r['id'] == roomId,
          orElse: () => {'room_no': '?'});
      roomNo = room['room_no'] as String? ?? '?';
      final capacity = room['capacity'] as int? ?? 1;
      final occupied = _inmates.where((i) => i['room_id'] == roomId).length;
      if (occupied >= capacity) {
        return _json(
            {'error': 'Room $roomNo is full ($occupied/$capacity)'}, 409);
      }
      bedNo = body['bed_no'] as int? ?? 1;
      if (bedNo < 1 || bedNo > capacity) {
        return _json({'error': 'Bed $bedNo is out of range (1-$capacity)'}, 409);
      }
      final bedTaken = _inmates.any(
          (i) => i['room_id'] == roomId && i['bed_no'] == bedNo);
      if (bedTaken) {
        return _json(
            {'error': 'Bed $bedNo in room $roomNo is already taken'}, 409);
      }
    }
    final id = _nextId('user');
    final username = _genUsername(name);
    final password = _genPassword();
    final email = body['email'] as String? ?? '';
    final inmate = <String, dynamic>{
      'id': id,
      'property_id': body['property_id'],
      'name': name,
      'phone': body['phone'] ?? '',
      'email': email,
      'username': username,
      'room_id': roomId,
      'room_no': roomNo,
      'bed_no': bedNo,
      'rent_amount': body['rent_amount'] ?? 0,
      'due_day': body['due_day'] ?? 1,
      'join_date': body['join_date'],
      'checkout_date': null,
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
      'email': email,
      'username': username,
      'kyc_verified': false,
      'password': _hashPassword(password),
    };
    return _json({'inmate': inmate, 'password': password}, 201);
  });

  // ── Inmate room change (re-validates capacity + bed uniqueness) ─────────
  router.patch('/inmates/<id>/room', (Request req, String id) async {
    final body = await _body(req);
    final inmate = _inmateById(id);
    if (inmate == null) return _json({'error': 'not found'}, 404);
    final property = _findById(_properties, inmate['property_id'] as String);
    final type = property?['type'] as String? ?? 'hostel';
    if (type == 'house' || type == 'office') {
      return _json({'error': 'This property has no rooms'}, 400);
    }
    final roomId = body['room_id'] as String? ?? '';
    if (roomId.isEmpty) return _json({'error': 'room_id is required'}, 400);
    final room = _findById(_rooms, roomId);
    if (room == null) return _json({'error': 'Room not found'}, 404);
    final roomNo = room['room_no'] as String;
    final capacity = room['capacity'] as int? ?? 1;
    final bedNo = body['bed_no'] as int? ?? 1;
    if (bedNo < 1 || bedNo > capacity) {
      return _json({'error': 'Bed $bedNo is out of range (1-$capacity)'}, 409);
    }
    final occupied = _inmates
        .where((i) => i['room_id'] == roomId && i['id'] != id)
        .length;
    if (occupied >= capacity) {
      return _json({'error': 'Room $roomNo is full ($occupied/$capacity)'}, 409);
    }
    final bedTaken = _inmates.any((i) =>
        i['room_id'] == roomId && i['bed_no'] == bedNo && i['id'] != id);
    if (bedTaken) {
      return _json({'error': 'Bed $bedNo in room $roomNo is already taken'}, 409);
    }
    inmate['room_id'] = roomId;
    inmate['room_no'] = roomNo;
    inmate['bed_no'] = bedNo;
    return _json({'inmate': inmate});
  });

  // ── Per-inmate invoice ──────────────────────────────────────────────────
  router.get('/inmates/<id>/invoice', (Request req, String id) {
    final inmate = _inmateById(id);
    if (inmate == null) return _json({'error': 'not found'}, 404);
    final month = req.url.queryParameters['month'];
    return _json({'invoice': _buildInvoice(inmate, month: month)});
  });

  router.post('/inmates/<id>/invoice/email', (Request req, String id) async {
    final inmate = _inmateById(id);
    if (inmate == null) return _json({'error': 'not found'}, 404);
    final email = inmate['email'] as String? ?? '';
    if (email.isEmpty) {
      return _json({'error': 'This inmate has no email on file'}, 400);
    }
    final body = await _body(req);
    final month = body['month'] as String?;
    final inv = _buildInvoice(inmate, month: month);
    await _sendEmail(
      to: email,
      subject:
          'Invoice ${inv['invoice_no']} — ${(inv['property'] as Map)['name']}',
      html: _invoiceHtml(inv),
    );
    return _json({'sent': true, 'to': email, 'invoice': inv});
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
    final propertyId = req.url.queryParameters['property_id'];
    final list = _payments
        .where((p) =>
            (inmateId == null || p['inmate_id'] == inmateId) &&
            (propertyId == null || p['property_id'] == propertyId))
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

  router.post('/checkouts/<id>/complete', (Request req, String id) async {
    final body = await _body(req);
    final c = _findById(_checkouts, id);
    if (c == null) return _json({'error': 'not found'}, 404);
    c['status'] = 'completed';
    c['refund'] = body['refund'] ?? 0;
    c['forfeit'] = body['forfeit'] ?? 0;
    c['completed_at'] = DateTime.now().toIso8601String().substring(0, 10);
    // Mark the inmate as checked out (stay-history end date).
    final inmate =
        _inmates.where((i) => i['id'] == c['inmate_id']).firstOrNull;
    if (inmate != null) {
      inmate['checkout_date'] = c['completed_at'];
    }
    // If the owner forfeited part of the deposit (damages), record a deduction.
    final forfeit = body['forfeit'] as int? ?? 0;
    if (forfeit > 0) {
      final d =
          _deposits.where((x) => x['inmate_id'] == c['inmate_id']).firstOrNull;
      if (d != null) {
        (d['deductions'] as List)
            .add({'reason': 'checkout forfeit', 'amount': forfeit});
      }
    }
    return _json({'checkout': c});
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
