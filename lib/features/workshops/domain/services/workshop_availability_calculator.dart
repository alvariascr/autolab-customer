import '../entities/booked_appointment_slot.dart';
import '../entities/workshop.dart';

class WorkshopAvailabilityResult {
  const WorkshopAvailabilityResult({
    required this.unavailableDates,
    required this.unavailableTimesByDate,
    required this.availableTimesByDate,
  });

  final List<DateTime> unavailableDates;
  final Map<DateTime, Set<String>> unavailableTimesByDate;
  final Map<DateTime, List<String>> availableTimesByDate;
}

class WorkshopAvailabilityCalculator {
  WorkshopAvailabilityCalculator({
    this.slotIntervalMinutes = 30,
    this.defaultServiceDurationMinutes = 60,
  }) {
    if (slotIntervalMinutes <= 0) {
      throw ArgumentError.value(
        slotIntervalMinutes,
        'slotIntervalMinutes',
        'must be greater than zero',
      );
    }

    if (defaultServiceDurationMinutes <= 0) {
      throw ArgumentError.value(
        defaultServiceDurationMinutes,
        'defaultServiceDurationMinutes',
        'must be greater than zero',
      );
    }
  }

  final int slotIntervalMinutes;
  final int defaultServiceDurationMinutes;

  WorkshopAvailabilityResult calculateMonth({
    required Workshop workshop,
    required DateTime month,
    required List<BookedAppointmentSlot> bookedSlots,
    double? serviceDurationHours,
    DateTime? now,
  }) {
    final startDate = DateTime(month.year, month.month);
    final endDate = DateTime(month.year, month.month + 1);
    final bookedByDate = _bookedTimesByDate(bookedSlots);
    final bookedIntervalsByDate = _bookedIntervalsByDate(bookedSlots);
    final availableByDate = <DateTime, List<String>>{};
    final unavailableDates = <DateTime>[];

    for (
      var date = startDate;
      date.isBefore(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final dateKey = DateTime(date.year, date.month, date.day);
      final availableTimes = availableTimesForDate(
        workshop: workshop,
        date: dateKey,
        bookedTimes: bookedByDate[dateKey] ?? const {},
        bookedIntervals: bookedIntervalsByDate[dateKey] ?? const [],
        serviceDurationHours: serviceDurationHours,
        now: now,
      );

      if (availableTimes.isEmpty) {
        unavailableDates.add(dateKey);
      } else {
        availableByDate[dateKey] = availableTimes;
      }
    }

    return WorkshopAvailabilityResult(
      unavailableDates: unavailableDates,
      unavailableTimesByDate: bookedByDate,
      availableTimesByDate: availableByDate,
    );
  }

  List<String> availableTimesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    DateTime? now,
  }) {
    final businessHour = _businessHourForDate(workshop.businessHours, date);
    if (businessHour == null || businessHour.isClosed) {
      return const [];
    }

    final openTime = _timeOnDate(date, businessHour.openTime);
    final closeTime = _timeOnDate(date, businessHour.closeTime);
    if (openTime == null ||
        closeTime == null ||
        !openTime.isBefore(closeTime)) {
      return const [];
    }

    final currentTime = now ?? DateTime.now();
    final serviceDuration = Duration(
      minutes: _serviceDurationMinutes(serviceDurationHours),
    );
    final slotInterval = Duration(minutes: slotIntervalMinutes);
    final blockedIntervals = bookedIntervals
        .map(
          (slot) => _TimeInterval(
            slot.start.toLocal(),
            slot.start.toLocal().add(
              Duration(
                minutes: _serviceDurationMinutesFromMinutes(
                  slot.durationMinutes,
                ),
              ),
            ),
          ),
        )
        .toList();

    blockedIntervals.addAll(
      bookedTimes
          .map((time) => _timeOnDate(date, time))
          .whereType<DateTime>()
          .map((start) => _TimeInterval(start, start.add(slotInterval)))
          .toList(),
    );

    final availableTimes = <String>[];
    for (
      var slotStart = openTime;
      !slotStart.add(serviceDuration).isAfter(closeTime);
      slotStart = slotStart.add(slotInterval)
    ) {
      final slotEnd = slotStart.add(serviceDuration);
      final isPast = !slotStart.isAfter(currentTime);
      final overlapsBooked = blockedIntervals.any((interval) {
        return slotStart.isBefore(interval.end) &&
            slotEnd.isAfter(interval.start);
      });

      if (!isPast && !overlapsBooked) {
        availableTimes.add(_formatTime(slotStart));
      }
    }

    return availableTimes;
  }

  Map<DateTime, Set<String>> _bookedTimesByDate(
    List<BookedAppointmentSlot> bookedSlots,
  ) {
    final bookedByDate = <DateTime, Set<String>>{};

    for (final slot in bookedSlots) {
      final localSlot = slot.start.toLocal();
      final dateKey = DateTime(localSlot.year, localSlot.month, localSlot.day);
      final timeKey = _formatTime(localSlot);

      bookedByDate.putIfAbsent(dateKey, () => <String>{}).add(timeKey);
    }

    return bookedByDate;
  }

  Map<DateTime, List<BookedAppointmentSlot>> _bookedIntervalsByDate(
    List<BookedAppointmentSlot> bookedSlots,
  ) {
    final bookedByDate = <DateTime, List<BookedAppointmentSlot>>{};

    for (final slot in bookedSlots) {
      final localSlot = slot.start.toLocal();
      final dateKey = DateTime(localSlot.year, localSlot.month, localSlot.day);

      bookedByDate
          .putIfAbsent(dateKey, () => <BookedAppointmentSlot>[])
          .add(
            BookedAppointmentSlot(
              start: localSlot,
              durationMinutes: slot.durationMinutes,
            ),
          );
    }

    return bookedByDate;
  }

  WorkshopBusinessHour? _businessHourForDate(
    List<WorkshopBusinessHour> businessHours,
    DateTime date,
  ) {
    // business_hours.day_of_week uses Monday=0 through Sunday=6.
    final dayOfWeek = date.weekday - 1;
    for (final businessHour in businessHours) {
      if (businessHour.dayOfWeek == dayOfWeek) {
        return businessHour;
      }
    }

    return null;
  }

  DateTime? _timeOnDate(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  int _serviceDurationMinutes(double? durationHours) {
    if (durationHours == null || durationHours <= 0) {
      return defaultServiceDurationMinutes;
    }

    return (durationHours * Duration.minutesPerHour).ceil();
  }

  int _serviceDurationMinutesFromMinutes(int? durationMinutes) {
    if (durationMinutes == null || durationMinutes <= 0) {
      return defaultServiceDurationMinutes;
    }

    return durationMinutes;
  }
}

class _TimeInterval {
  const _TimeInterval(this.start, this.end);

  final DateTime start;
  final DateTime end;
}
