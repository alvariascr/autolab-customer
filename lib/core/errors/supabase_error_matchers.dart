import 'package:supabase_flutter/supabase_flutter.dart';

/// Matches Postgres RPCs that `raise exception 'Authentication required'`
/// when `auth.uid()` is null even though the client still has a
/// seemingly-valid local session (e.g. a stale/expiring JWT).
bool isAuthRequiredError(PostgrestException error) {
  return error.message.contains('Authentication required');
}
