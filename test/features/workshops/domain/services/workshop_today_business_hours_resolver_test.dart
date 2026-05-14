import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_today_business_hours_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkshopTodayBusinessHoursResolver', () {
    test('devuelve solo el horario del dia actual', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final result = resolver.resolve(const [
        WorkshopBusinessHour(
          dayOfWeek: DateTime.monday,
          openTime: '08:00:00',
          closeTime: '18:00:00',
          isClosed: false,
        ),
        WorkshopBusinessHour(
          dayOfWeek: DateTime.saturday,
          openTime: '',
          closeTime: '',
          isClosed: true,
        ),
      ], now: DateTime(2026, 5, 16));

      expect(result?.dayOfWeek, DateTime.saturday);
      expect(result?.isClosed, isTrue);
    });

    test('retorna null cuando no hay horario para hoy', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final result = resolver.resolve(const [
        WorkshopBusinessHour(
          dayOfWeek: DateTime.monday,
          openTime: '08:00:00',
          closeTime: '18:00:00',
          isClosed: false,
        ),
      ], now: DateTime(2026, 5, 16));

      expect(result, isNull);
    });
  });
}
