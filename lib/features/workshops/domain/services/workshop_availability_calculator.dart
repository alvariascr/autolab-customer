import '../../../../core/utils/costa_rica_time.dart';
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

  /// [now] must be Costa Rica wall-clock time (see [nowInCostaRica]) --
  /// not UTC, not the device's own local time -- to match [workshop]'s
  /// business hours and [bookedSlots], which are already in that same
  /// convention. Omit it to default to the current moment in Costa Rica.
  WorkshopAvailabilityResult calculateMonth({
    required Workshop workshop,
    required DateTime month,
    required List<BookedAppointmentSlot> bookedSlots,
    double? serviceDurationHours,
    bool isInspectionService = false,
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
        isInspectionService: isInspectionService,
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

  /// See [calculateMonth] for the [now] parameter's timezone contract.
  List<String> availableTimesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    bool isInspectionService = false,
    DateTime? now,
  }) {
    return _timesForDate(
      workshop: workshop,
      date: date,
      bookedTimes: bookedTimes,
      bookedIntervals: bookedIntervals,
      serviceDurationHours: serviceDurationHours,
      isInspectionService: isInspectionService,
      now: now,
    ).availableTimes;
  }

  /// See [calculateMonth] for the [now] parameter's timezone contract.
  Set<String> unavailableTimesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    bool isInspectionService = false,
    DateTime? now,
  }) {
    return _timesForDate(
      workshop: workshop,
      date: date,
      bookedTimes: bookedTimes,
      bookedIntervals: bookedIntervals,
      serviceDurationHours: serviceDurationHours,
      isInspectionService: isInspectionService,
      now: now,
    ).unavailableTimes;
  }

  _DayAvailability _timesForDate({
    required Workshop workshop,
    required DateTime date,
    required Set<String> bookedTimes,
    List<BookedAppointmentSlot> bookedIntervals = const [],
    double? serviceDurationHours,
    bool isInspectionService = false,
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

    final currentTime = now ?? nowInCostaRica();
    final slotInterval = Duration(minutes: slotIntervalMinutes);
    final serviceDuration = _serviceDuration(
      serviceDurationHours: serviceDurationHours,
    );
    final normalCapacity = workshop.activeEmployeeCount;
    final inspectionCapacity = workshop.activeEmployeeCount * 2;
    final capacity = isInspectionService ? inspectionCapacity : normalCapacity;

    if (capacity <= 0) {
      return const _DayAvailability();
    }

    final availableTimes = <String>[];
    final unavailableTimes = <String>{};
    for (
      var slotStart = openTime;
      !slotStart.add(slotInterval).isAfter(closeTime);
      slotStart = slotStart.add(slotInterval)
    ) {
      final isPast = !slotStart.isAfter(currentTime);
      final slotEnd = slotStart.add(serviceDuration);
      final fitsBusinessHours = !slotEnd.isAfter(closeTime);
      final hasCapacity = _hasCapacityForServiceWindow(
        slotStart: slotStart,
        slotEnd: slotEnd,
        slotInterval: slotInterval,
        bookedTimes: bookedTimes,
        bookedSlots: bookedIntervals,
        capacity: capacity,
        isInspectionService: isInspectionService,
      );

      if (isPast) {
        continue;
      }

      if (fitsBusinessHours && hasCapacity) {
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
              isInspectionService: slot.isInspectionService,
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

  Duration _serviceDuration({double? serviceDurationHours}) {
    final durationMinutes =
        serviceDurationHours == null ||
            !serviceDurationHours.isFinite ||
            serviceDurationHours <= 0
        ? defaultServiceDurationMinutes
        : (serviceDurationHours * Duration.minutesPerHour).ceil();

    return Duration(minutes: durationMinutes);
  }

  bool _hasCapacityForServiceWindow({
    required DateTime slotStart,
    required DateTime slotEnd,
    required Duration slotInterval,
    required Set<String> bookedTimes,
    required List<BookedAppointmentSlot> bookedSlots,
    required int capacity,
    required bool isInspectionService,
  }) {
    if (isInspectionService) {
      final hourStart = DateTime(
        slotStart.year,
        slotStart.month,
        slotStart.day,
        slotStart.hour,
      );
      final hourEnd = hourStart.add(const Duration(hours: 1));
      final sameHourInspectionCount = bookedSlots.where((slot) {
        return slot.isInspectionService &&
            !slot.start.isBefore(hourStart) &&
            slot.start.isBefore(hourEnd);
      }).length;

      return sameHourInspectionCount < capacity;
    }

    if (bookedSlots.isEmpty) {
      return !bookedTimes.contains(_formatTime(slotStart)) || capacity > 1;
    }

    for (
      var segmentStart = slotStart;
      segmentStart.isBefore(slotEnd);
      segmentStart = segmentStart.add(slotInterval)
    ) {
      final segmentEnd = segmentStart.add(slotInterval).isAfter(slotEnd)
          ? slotEnd
          : segmentStart.add(slotInterval);
      final overlapping = _overlappingAppointmentCount(
        segmentStart: segmentStart,
        segmentEnd: segmentEnd,
        bookedSlots: bookedSlots,
        isInspectionService: isInspectionService,
      );

      if (overlapping >= capacity) {
        return false;
      }
    }

    return true;
  }

  int _overlappingAppointmentCount({
    required DateTime segmentStart,
    required DateTime segmentEnd,
    required List<BookedAppointmentSlot> bookedSlots,
    required bool isInspectionService,
  }) {
    var count = 0;

    for (final slot in bookedSlots) {
      if (slot.isInspectionService != isInspectionService) {
        continue;
      }

      final bookedEnd = slot.start.add(
        Duration(
          minutes: slot.durationMinutes ?? defaultServiceDurationMinutes,
        ),
      );

      if (slot.start.isBefore(segmentEnd) && bookedEnd.isAfter(segmentStart)) {
        count++;
      }
    }

    return count;
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
