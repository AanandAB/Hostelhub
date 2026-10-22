/// Tolerant JSON scalar readers.
///
/// SQLite (D1) has no boolean type — it returns `0`/`1` — while Postgres and
/// the Dart dev server return real booleans. Casting with `as bool?` throws a
/// TypeError on the former, and because the callers wrap repository calls in
/// try/catch the failure surfaces as a silent "nothing happened" on screen.
/// Always read boolean fields through [jsonBool].
library;

/// Reads a boolean that may arrive as `true`/`false`, `0`/`1`, or `"1"`.
bool jsonBool(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final v = value.trim().toLowerCase();
    if (v == 'true' || v == '1') return true;
    if (v == 'false' || v == '0') return false;
  }
  return defaultValue;
}
