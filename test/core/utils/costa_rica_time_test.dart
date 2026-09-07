import 'package:autolab_customer/core/utils/costa_rica_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('costa_rica_time', () {
    test('utcToCostaRicaLocalTime subtracts 6 hours from UTC', () {
      final utc = DateTime.utc(2026, 9, 7, 14, 30);

      final costaRicaTime = utcToCostaRicaLocalTime(utc);

      expect(costaRicaTime.year, 2026);
      expect(costaRicaTime.month, 9);
      expect(costaRicaTime.day, 7);
      expect(costaRicaTime.hour, 8);
      expect(costaRicaTime.minute, 30);
    });

    test(
      'utcToCostaRicaLocalTime rolls back to the previous day near midnight',
      () {
        final utc = DateTime.utc(2026, 9, 7, 3, 0);

        final costaRicaTime = utcToCostaRicaLocalTime(utc);

        expect(costaRicaTime.day, 6);
        expect(costaRicaTime.hour, 21);
      },
    );

    test('costaRicaLocalTimeToUtc adds 6 hours to Costa Rica time', () {
      final costaRicaTime = DateTime(2026, 9, 7, 8, 30);

      final utc = costaRicaLocalTimeToUtc(costaRicaTime);

      expect(utc.isUtc, isTrue);
      expect(utc.year, 2026);
      expect(utc.month, 9);
      expect(utc.day, 7);
      expect(utc.hour, 14);
      expect(utc.minute, 30);
    });

    test('round-trips a moment through UTC and back', () {
      final originalUtc = DateTime.utc(2026, 9, 7, 14, 30, 15);

      final roundTripped = costaRicaLocalTimeToUtc(
        utcToCostaRicaLocalTime(originalUtc),
      );

      expect(roundTripped, originalUtc);
    });

    test('costaRicaLocalTimeToUtc rolls over to the next UTC day past 18:00 '
        'Costa Rica time -- DateTime.utc normalizes an hour argument > 23 on '
        'its own, no explicit .add() needed', () {
      final costaRicaTime = DateTime(2026, 9, 7, 20, 0);

      final utc = costaRicaLocalTimeToUtc(costaRicaTime);

      expect(utc.day, 8);
      expect(utc.hour, 2);
    });

    test(
      'nowInCostaRica matches utcToCostaRicaLocalTime(DateTime.now().toUtc())',
      () {
        // Bracket nowInCostaRica() between two values built the exact same
        // way, right before and right after calling it. Both sides go
        // through the same local-DateTime-from-computed-fields conversion,
        // so this stays correct regardless of the test machine's own
        // timezone -- unlike comparing against a genuinely UTC-flagged
        // DateTime.now().toUtc().subtract(...), which would only happen to
        // pass on a machine whose real timezone is already UTC-6.
        final before = utcToCostaRicaLocalTime(DateTime.now().toUtc());
        final result = nowInCostaRica();
        final after = utcToCostaRicaLocalTime(DateTime.now().toUtc());

        expect(
          result.isBefore(before.subtract(const Duration(seconds: 1))),
          isFalse,
        );
        expect(result.isAfter(after.add(const Duration(seconds: 1))), isFalse);
      },
    );
  });
}
