// Costa Rica does not observe daylight saving time -- the UTC-6 offset is
// constant year-round, so a fixed Duration is correct and never needs
// DST-calendar-aware logic.
DateTime utcToCostaRicaLocalTime(DateTime dateTime) {
  final costaRicaTime = dateTime.toUtc().subtract(const Duration(hours: 6));
  return DateTime(
    costaRicaTime.year,
    costaRicaTime.month,
    costaRicaTime.day,
    costaRicaTime.hour,
    costaRicaTime.minute,
    costaRicaTime.second,
    costaRicaTime.millisecond,
    costaRicaTime.microsecond,
  );
}

DateTime costaRicaLocalTimeToUtc(DateTime dateTime) {
  return DateTime.utc(
    dateTime.year,
    dateTime.month,
    dateTime.day,
    dateTime.hour + 6,
    dateTime.minute,
    dateTime.second,
    dateTime.millisecond,
    dateTime.microsecond,
  );
}

/// The current moment in Costa Rica wall-clock time. Callers comparing
/// against business hours or booked slots (both already Costa Rica wall-
/// clock, see appointment_booking_remote_data_source.dart) should use this
/// instead of DateTime.now(), which returns the device's own local time.
DateTime nowInCostaRica() => utcToCostaRicaLocalTime(DateTime.now().toUtc());
