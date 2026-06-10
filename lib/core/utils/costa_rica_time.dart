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
