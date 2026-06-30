class BookedAppointmentSlot {
  const BookedAppointmentSlot({
    required this.start,
    this.durationMinutes,
    this.isInspectionService = false,
  });

  final DateTime start;
  final int? durationMinutes;
  final bool isInspectionService;
}
