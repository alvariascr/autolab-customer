import 'package:autolab_customer/features/workshops/domain/entities/booked_appointment_slot.dart';
import 'package:autolab_customer/features/workshops/domain/entities/workshop.dart';
import 'package:autolab_customer/features/workshops/domain/services/workshop_availability_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final calculator = WorkshopAvailabilityCalculator();

  test('rejects non-positive slot interval', () {
    expect(
      () => WorkshopAvailabilityCalculator(slotIntervalMinutes: 0),
      throwsArgumentError,
    );
  });

  test('rejects non-positive default service duration', () {
    expect(
      () => WorkshopAvailabilityCalculator(defaultServiceDurationMinutes: 0),
      throwsArgumentError,
    );
  });

  test('generates 30 minute slots inside workshop business hours', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '07:00:00',
            closeTime: '09:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['07:00', '07:30', '08:00', '08:30']);
  });

  test('maps business hours day zero to monday', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '07:00:00',
            closeTime: '08:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['07:00', '07:30']);
  });

  test('returns empty slots when the workshop is closed', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '',
            closeTime: '',
            isClosed: true,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      now: DateTime(2026, 5, 31),
    );

    expect(times, isEmpty);
  });

  test('returns empty slots when business hours contain invalid times', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '24:00:00',
            closeTime: '25:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      now: DateTime(2026, 5, 31),
    );

    expect(times, isEmpty);
  });

  test('excludes past slots and booked slots', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '07:00:00',
            closeTime: '10:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {'08:30'},
      serviceDurationHours: 0.5,
      now: DateTime(2026, 6, 1, 7, 30),
    );

    expect(times, ['08:00', '09:00', '09:30']);
  });

  test('blocks only the exact booked slot', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '12:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      bookedIntervals: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 90,
        ),
      ],
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['09:30', '10:00', '10:30', '11:00', '11:30']);
  });

  test('keeps overlapping slots available while capacity remains', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '11:00:00',
            isClosed: false,
            slotCapacity: 2,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      bookedIntervals: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 60,
        ),
      ],
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['09:00', '09:30', '10:00', '10:30']);
  });

  test('blocks the exact slot when configured capacity is reached', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '11:00:00',
            isClosed: false,
            slotCapacity: 2,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      bookedIntervals: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 90,
        ),
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 90,
        ),
      ],
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['09:30', '10:00', '10:30']);
  });

  test('tracks capacity per exact slot', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '11:00:00',
            isClosed: false,
            slotCapacity: 2,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      bookedIntervals: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 60,
        ),
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 10),
          durationMinutes: 60,
        ),
      ],
      serviceDurationHours: 1,
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['09:00', '09:30', '10:00', '10:30']);

    final unavailableTimes = calculator.unavailableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '11:00:00',
            isClosed: false,
            slotCapacity: 2,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      bookedIntervals: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 60,
        ),
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 10),
          durationMinutes: 60,
        ),
      ],
      serviceDurationHours: 1,
      now: DateTime(2026, 5, 31),
    );

    expect(unavailableTimes, isEmpty);
  });

  test('returns full exact slots as unavailable times for visual blocking', () {
    final result = calculator.calculateMonth(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '09:00:00',
            closeTime: '11:00:00',
            isClosed: false,
            slotCapacity: 2,
          ),
        ],
      ),
      month: DateTime(2026, 6),
      bookedSlots: [
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 90,
        ),
        BookedAppointmentSlot(
          start: DateTime(2026, 6, 1, 9),
          durationMinutes: 90,
        ),
      ],
      serviceDurationHours: 0.5,
      now: DateTime(2026, 5, 31),
    );

    final date = DateTime(2026, 6, 1);
    expect(result.availableTimesByDate[date], ['09:30', '10:00', '10:30']);
    expect(result.unavailableTimesByDate[date], {'09:00'});
  });

  test('keeps future slots available for the current day', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '07:00:00',
            closeTime: '17:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      serviceDurationHours: 0.5,
      now: DateTime(2026, 6, 1, 8, 24),
    );

    expect(times.first, '08:30');
    expect(times.last, '16:30');
  });

  test('uses slot interval when service has no duration', () {
    final times = calculator.availableTimesForDate(
      workshop: _workshop(
        hours: const [
          WorkshopBusinessHour(
            dayOfWeek: 0,
            openTime: '07:00:00',
            closeTime: '09:00:00',
            isClosed: false,
          ),
        ],
      ),
      date: DateTime(2026, 6, 1),
      bookedTimes: const {},
      now: DateTime(2026, 5, 31),
    );

    expect(times, ['07:00', '07:30', '08:00', '08:30']);
  });
}

Workshop _workshop({required List<WorkshopBusinessHour> hours}) {
  return Workshop(
    id: 'workshop-1',
    name: 'Workshop',
    description: '',
    locationAddress: '',
    avatarUrl: '',
    coverUrl: '',
    latitude: 0,
    longitude: 0,
    deliveryRadiusKm: 0,
    businessHours: hours,
  );
}
