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
}
