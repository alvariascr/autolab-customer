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
    final bookedSlotsByDate = _bookedSlotsByDate(bookedSlots);
    final availableByDate = <DateTime, List<String>>{};
    final unavailableTimesByDate = <DateTime, Set<String>>{};
    final unavailableDates = <DateTime>[];

    for (
      var date = startDate;
      date.isBefore(endDate);
      date = date.add(const Duration(days: 1))
    ) {
      final dateKey = DateTime(date.year, date.month, date.day);
      final dayAvailability = _timesForDate(
        workshop: workshop,
        date: dateKey,
        bookedTimes: bookedByDate[dateKey] ?? const {},
        bookedIntervals: bookedSlotsByDate[dateKey] ?? const [],
        serviceDurationHours: serviceDurationHours,
        now: now,
      );

      if (dayAvailability.availableTimes.isEmpty) {
        unavailableDates.add(dateKey);
      } else {
        availableByDate[dateKey] = dayAvailability.availableTimes;
      }

      if (dayAvailability.unavailableTimes.isNotEmpty) {
        unavailableTimesByDate[dateKey] = dayAvailability.unavailableTimes;
      }
    }

    return WorkshopAvailabilityResult(
      unavailableDates: unavailableDates,
      unavailableTimesByDate: unavailableTimesByDate,
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
    return _timesForDate(
      workshop: workshop,
      date: date,
      bookedTimes: bookedTimes,
      bookedIntervals: bookedIntervals,
      serviceDurationHours: serviceDurationHours,
      now: now,
    ).availableTimes;
  }

  Set<String> unavailableTimesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    DateTime? now,
  }) {
    return _timesForDate(
      workshop: workshop,
      date: date,
      bookedTimes: bookedTimes,
      bookedIntervals: bookedIntervals,
      serviceDurationHours: serviceDurationHours,
      now: now,
    ).unavailableTimes;
  }

  _DayAvailability _timesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    DateTime? now,
  }) {
    final businessHour = _businessHourForDate(workshop.businessHours, date);
    if (businessHour == null || businessHour.isClosed) {
      return const _DayAvailability();
    }

    final openTime = _timeOnDate(date, businessHour.openTime);
    final closeTime = _timeOnDate(date, businessHour.closeTime);
    if (openTime == null ||
        closeTime == null ||
        !openTime.isBefore(closeTime)) {
      return const _DayAvailability();
    }

    final currentTime = now ?? DateTime.now();
    final slotInterval = Duration(minutes: slotIntervalMinutes);
    final bookedSlotCounts = _bookedSlotCounts(
      bookedTimes: bookedTimes,
      bookedSlots: bookedIntervals,
    );

    final availableTimes = <String>[];
    final unavailableTimes = <String>{};
    for (
      var slotStart = openTime;
      !slotStart.add(slotInterval).isAfter(closeTime);
      slotStart = slotStart.add(slotInterval)
    ) {
      final isPast = !slotStart.isAfter(currentTime);
      final timeKey = _formatTime(slotStart);
      final capacity = businessHour.slotCapacity <= 0
          ? 1
          : businessHour.slotCapacity;
      final hasCapacity = (bookedSlotCounts[timeKey] ?? 0) < capacity;

      if (isPast) {
        continue;
      }

      if (hasCapacity) {
        availableTimes.add(_formatTime(slotStart));
      } else {
        unavailableTimes.add(_formatTime(slotStart));
      }
    }

    return _DayAvailability(
      availableTimes: availableTimes,
      unavailableTimes: unavailableTimes,
    );
  }

  Map<DateTime, Set<String>> _bookedTimesByDate(
    List<BookedAppointmentSlot> bookedSlots,
  ) {
    final bookedByDate = <DateTime, Set<String>>{};

    for (final slot in bookedSlots) {
      final dateKey = DateTime(
        slot.start.year,
        slot.start.month,
        slot.start.day,
      );
      final timeKey = _formatTime(slot.start);

      bookedByDate.putIfAbsent(dateKey, () => <String>{}).add(timeKey);
    }

    return bookedByDate;
  }

  Map<DateTime, List<BookedAppointmentSlot>> _bookedSlotsByDate(
    List<BookedAppointmentSlot> bookedSlots,
  ) {
    final bookedByDate = <DateTime, List<BookedAppointmentSlot>>{};

    for (final slot in bookedSlots) {
      final dateKey = DateTime(
        slot.start.year,
        slot.start.month,
        slot.start.day,
      );

      bookedByDate
          .putIfAbsent(dateKey, () => <BookedAppointmentSlot>[])
          .add(
            BookedAppointmentSlot(
              start: slot.start,
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

  Map<String, int> _bookedSlotCounts({
    required Set<String> bookedTimes,
    required List<BookedAppointmentSlot> bookedSlots,
  }) {
    final counts = <String, int>{};

    if (bookedSlots.isEmpty) {
      for (final time in bookedTimes) {
        counts.update(time, (count) => count + 1, ifAbsent: () => 1);
      }
      return counts;
    }

    for (final slot in bookedSlots) {
      final time = _formatTime(slot.start);
      counts.update(time, (count) => count + 1, ifAbsent: () => 1);
    }

    return counts;
  }
}

class _DayAvailability {
  const _DayAvailability({
    this.availableTimes = const [],
    this.unavailableTimes = const {},
  });

  final List<String> availableTimes;
  final Set<String> unavailableTimes;
}
