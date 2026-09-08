import 'package:supabase_flutter/supabase_flutter.dart';

/// Matches errors indicating an unauthenticated or stale session state.
///
/// Handles:
/// 1. Custom Postgres RPC exceptions (`raise exception 'Authentication
///    required'`), used by our own `toggle_customer_favorite_*` RPCs.
/// 2. PostgREST JWT errors (`PGRST301`, `PGRST302`).
/// 3. HTTP `401`/`403` status codes surfaced as the error code.
/// 4. Standard Supabase Auth/JWT message patterns (e.g. "JWT expired").
bool isAuthRequiredError(PostgrestException error) {
  final code = error.code?.toUpperCase();
  if (code == 'PGRST301' ||
      code == 'PGRST302' ||
      code == '401' ||
      code == '403') {
    return true;
  }

  final message = error.message.toLowerCase();
  final details = error.details?.toString().toLowerCase() ?? '';

  return message.contains('authentication required') ||
      message.contains('jwt expired') ||
      message.contains('invalid jwt') ||
      message.contains('jwt is invalid') ||
      details.contains('jwt expired');
}
