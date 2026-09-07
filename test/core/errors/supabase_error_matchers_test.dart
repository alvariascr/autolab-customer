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

    test(
      'is case-sensitive and does not match a differently-cased message',
      () {
        const error = PostgrestException(message: 'authentication required');

        expect(isAuthRequiredError(error), isFalse);
      },
    );
  });
}
