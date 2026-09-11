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

  group('WorkshopTodayBusinessHoursResolver.statusNow', () {
    const hours = [
      WorkshopBusinessHour(
        dayOfWeek: DateTime.saturday,
        openTime: '08:00:00',
        closeTime: '17:00:00',
        isClosed: false,
      ),
    ];

    test('abierto cuando la hora actual es antes del cierre', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(
        hours,
        now: DateTime(2026, 5, 16, 16, 59),
      );

      expect(status, isA<WorkshopOpen>());
      expect((status as WorkshopOpen).formattedCloseTime, '17:00');
    });

    test('cerrado cuando aun no llega la hora de apertura', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(
        hours,
        now: DateTime(2026, 5, 16, 6, 30),
      );

      expect(status, isA<WorkshopClosed>());
    });

    test('cerrado cuando ya pasó la hora de cierre configurada, aunque el día '
        'no esté marcado como cerrado', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(
        hours,
        now: DateTime(2026, 5, 16, 17, 14),
      );

      expect(status, isA<WorkshopClosed>());
    });

    test(
      'cerrado cuando la hora actual coincide exactamente con el cierre',
      () {
        const resolver = WorkshopTodayBusinessHoursResolver();

        final status = resolver.statusNow(
          hours,
          now: DateTime(2026, 5, 16, 17, 0),
        );

        expect(
          status,
          isA<WorkshopClosed>(),
          reason: 'a la hora exacta de cierre ya no debe contar como abierto',
        );
      },
    );

    test('cerrado cuando el día está marcado como cerrado', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(const [
        WorkshopBusinessHour(
          dayOfWeek: DateTime.saturday,
          openTime: '',
          closeTime: '',
          isClosed: true,
        ),
      ], now: DateTime(2026, 5, 16, 10, 0));

      expect(status, isA<WorkshopClosed>());
    });

    test('desconocido cuando el taller no tiene horarios cargados', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(
        const [],
        now: DateTime(2026, 5, 16, 10, 0),
      );

      expect(status, isA<WorkshopUnknown>());
    });

    test('desconocido cuando la hora de cierre tiene un formato inválido', () {
      const resolver = WorkshopTodayBusinessHoursResolver();

      final status = resolver.statusNow(const [
        WorkshopBusinessHour(
          dayOfWeek: DateTime.saturday,
          openTime: '08:00:00',
          closeTime: 'sin-hora',
          isClosed: false,
        ),
      ], now: DateTime(2026, 5, 16, 10, 0));

      expect(status, isA<WorkshopUnknown>());
    });

    test(
      'desconocido cuando la hora de apertura tiene un formato inválido',
      () {
        const resolver = WorkshopTodayBusinessHoursResolver();

        final status = resolver.statusNow(const [
          WorkshopBusinessHour(
            dayOfWeek: DateTime.saturday,
            openTime: 'sin-hora',
            closeTime: '17:00:00',
            isClosed: false,
          ),
        ], now: DateTime(2026, 5, 16, 10, 0));

        expect(status, isA<WorkshopUnknown>());
      },
    );
  });
}
