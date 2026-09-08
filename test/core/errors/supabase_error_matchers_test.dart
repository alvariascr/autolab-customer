import 'package:autolab_customer/core/errors/supabase_error_matchers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('isAuthRequiredError', () {
    test(
      'returns true when the message is exactly "Authentication required"',
      () {
        const error = PostgrestException(message: 'Authentication required');

        expect(isAuthRequiredError(error), isTrue);
      },
    );

    test('returns true when the message contains it alongside other text', () {
      const error = PostgrestException(
        message: 'Authentication required to perform this action',
        code: 'P0001',
      );

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns false for unrelated Postgrest errors', () {
      const error = PostgrestException(
        message: 'permission denied for table customer_favorites',
        code: '42501',
      );

      expect(isAuthRequiredError(error), isFalse);
    });

    test('is case-insensitive on the message text', () {
      const error = PostgrestException(message: 'AUTHENTICATION REQUIRED.');

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns true for a PGRST301 (JWT expired) error code', () {
      const error = PostgrestException(
        message: 'JWT expired',
        code: 'PGRST301',
      );

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns true for a PGRST302 error code regardless of casing', () {
      const error = PostgrestException(
        message: 'invalid claim',
        code: 'pgrst302',
      );

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns true for an HTTP 401 status surfaced as the code', () {
      const error = PostgrestException(message: 'Unauthorized', code: '401');

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns true for an HTTP 403 status surfaced as the code', () {
      const error = PostgrestException(message: 'Forbidden', code: '403');

      expect(isAuthRequiredError(error), isTrue);
    });

    test('returns true when the message mentions an invalid JWT', () {
      const error = PostgrestException(message: 'invalid JWT');

      expect(isAuthRequiredError(error), isTrue);
    });

    test(
      'returns true for a native "JWT expired" message with no error code',
      () {
        const error = PostgrestException(message: 'JWT expired');

        expect(isAuthRequiredError(error), isTrue);
      },
    );

    test('returns true when only the details field mentions a JWT expiry', () {
      const error = PostgrestException(
        message: 'Unexpected error',
        details: 'jwt expired at 2026-09-08T00:00:00Z',
      );

      expect(isAuthRequiredError(error), isTrue);
    });

    test(
      'returns false when neither code nor message indicate an auth failure',
      () {
        const error = PostgrestException(
          message: 'cart_product_stock_unavailable',
          code: 'P0001',
        );

        expect(isAuthRequiredError(error), isFalse);
      },
    );
  });
}
