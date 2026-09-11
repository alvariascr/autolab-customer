import '../../../../core/utils/costa_rica_time.dart';
import '../entities/workshop.dart';

class WorkshopTodayBusinessHoursResolver {
  const WorkshopTodayBusinessHoursResolver();

  WorkshopBusinessHour? resolve(
    List<WorkshopBusinessHour> hours, {
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).weekday;

    for (final hour in hours) {
      if (hour.dayOfWeek == today) {
        return hour;
      }
    }

    return null;
  }

  /// Whether the workshop is open right now (Costa Rica wall-clock, matching
  /// how business hours are stored), not just whether today has hours
  /// configured -- a close time in the past means closed even though the
  /// day itself isn't marked closed.
  WorkshopOpenStatus statusNow(
    List<WorkshopBusinessHour> hours, {
    DateTime? now,
  }) {
    if (hours.isEmpty) {
      return const WorkshopUnknown();
    }

    final currentTime = now ?? nowInCostaRica();
    final todayHours = resolve(hours, now: currentTime);

    if (todayHours == null || todayHours.isClosed) {
      return const WorkshopClosed();
    }

    final closeTime = _timeOnDate(currentTime, todayHours.closeTime);
    if (closeTime == null) {
      return const WorkshopUnknown();
    }

    if (!currentTime.isBefore(closeTime)) {
      return const WorkshopClosed();
    }

    return WorkshopOpen(todayHours.closeTime);
  }

  DateTime? _timeOnDate(DateTime date, String time) {
    final parts = time.split(':');
    if (parts.length < 2) {
      return null;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }

    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}

/// Sealed so callers switch over the concrete subtype instead of a `kind`
/// enum plus a nullable close time -- [WorkshopOpen.formattedCloseTime] is
/// only reachable when the compiler has already proven the workshop is
/// open, so no call site needs a `!` to get at it.
sealed class WorkshopOpenStatus {
  const WorkshopOpenStatus();
}

class WorkshopOpen extends WorkshopOpenStatus {
  const WorkshopOpen(this.closeTime);

  /// Raw "HH:mm:ss" (or "HH:mm") as stored on the business hour row.
  final String closeTime;

  /// The close time as "HH:mm".
  String get formattedCloseTime =>
      closeTime.length >= 5 ? closeTime.substring(0, 5) : closeTime;
}

class WorkshopClosed extends WorkshopOpenStatus {
  const WorkshopClosed();
}

class WorkshopUnknown extends WorkshopOpenStatus {
  const WorkshopUnknown();
}
