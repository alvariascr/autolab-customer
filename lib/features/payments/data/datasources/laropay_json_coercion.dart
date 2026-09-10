/// Shared JSON-value coercion helpers for the Laropay data sources, which
/// both read fields off Supabase rows and Edge Function responses where a
/// numeric/string value may arrive as its native type or as a string.
library;

String stringValue(Object? value) => value?.toString().trim() ?? '';

String? nullableStringValue(Object? value) {
  final normalized = stringValue(value);
  return normalized.isEmpty ? null : normalized;
}

/// Returns `null` when [value] is absent or cannot be parsed as a number,
/// rather than a magic fallback (`0`, `NaN`) -- callers decide what an
/// absent/invalid value means for them (reject it, default it, etc.).
double? numberValueOrNull(Object? value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(stringValue(value));
}
