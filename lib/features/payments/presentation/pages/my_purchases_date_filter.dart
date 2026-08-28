part of 'my_purchases_page.dart';

class _PurchaseDateFilterResult {
  const _PurchaseDateFilterResult(this.range);

  final DateTimeRange? range;
}

class _PurchaseDateFilterSheet extends StatefulWidget {
  const _PurchaseDateFilterSheet({
    required this.initialRange,
    required this.firstDay,
    required this.lastDay,
  });

  final DateTimeRange? initialRange;
  final DateTime firstDay;
  final DateTime lastDay;

  @override
  State<_PurchaseDateFilterSheet> createState() =>
      _PurchaseDateFilterSheetState();
}

class _PurchaseDateFilterSheetState extends State<_PurchaseDateFilterSheet> {
  late DateTime _focusedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialRange?.start;
    _rangeEnd = widget.initialRange?.end;
    _focusedDay = _rangeStart ?? widget.lastDay;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: AutolabCustomer.customerSurfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AutolabCustomer.customerBorderColor(context),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AutolabCustomer.customerSecondaryTextColor(
                    context,
                  ).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.myPurchasesFilterByDateAction,
                    style: AutolabCustomer.h3.copyWith(
                      color: AutolabCustomer.customerTextColor(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AutolabCustomer.customerTextColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TableCalendar<void>(
              locale: 'es',
              firstDay: widget.firstDay,
              lastDay: widget.lastDay,
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
              enabledDayPredicate: (day) {
                final date = _dateOnly(day);
                return !date.isBefore(_dateOnly(widget.firstDay)) &&
                    !date.isAfter(_dateOnly(widget.lastDay));
              },
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _rangeStart = start == null ? null : _dateOnly(start);
                  _rangeEnd = end == null ? null : _dateOnly(end);
                  _focusedDay = focusedDay;
                });
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  final date = _dateOnly(selectedDay);
                  if (_rangeStart == null ||
                      (_rangeStart != null && _rangeEnd != null)) {
                    _rangeStart = date;
                    _rangeEnd = null;
                  } else if (date.isBefore(_rangeStart!)) {
                    _rangeEnd = _rangeStart;
                    _rangeStart = date;
                  } else {
                    _rangeEnd = date;
                  }
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) =>
                  setState(() => _focusedDay = focusedDay),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: AutolabCustomer.body.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w900,
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: AutolabCustomer.customerTextColor(context),
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: AutolabCustomer.customerTextColor(context),
                ),
                titleTextFormatter: (date, locale) {
                  final month = DateFormat.MMMM(locale).format(date);
                  return l10n.appointmentMonthYearTitle(
                    _capitalize(month),
                    date.year,
                  );
                },
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
                weekendStyle: AutolabCustomer.caption.copyWith(
                  color: AutolabCustomer.customerTextColor(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
              calendarStyle: const CalendarStyle(outsideDaysVisible: true),
              calendarBuilders: CalendarBuilders<void>(
                defaultBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day),
                disabledBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, disabled: true),
                outsideBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, outside: true),
                todayBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, today: true),
                selectedBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, selected: true),
                rangeStartBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, selected: true),
                rangeEndBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, selected: true),
                withinRangeBuilder: (context, day, focusedDay) =>
                    _PurchaseCalendarDay(day: day, inRange: true),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const _PurchaseDateFilterResult(null),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AutolabCustomer.customerTextColor(
                        context,
                      ),
                      side: BorderSide(
                        color: AutolabCustomer.customerBorderColor(context),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AutolabCustomer.radiusSm,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      l10n.myPurchasesClearFilterAction,
                      style: const TextStyle(
                        fontFamily: AutolabCustomer.primaryFont,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _rangeStart == null
                        ? null
                        : () {
                            final start = _rangeStart!;
                            Navigator.pop(
                              context,
                              _PurchaseDateFilterResult(
                                DateTimeRange(
                                  start: start,
                                  end: _rangeEnd ?? start,
                                ),
                              ),
                            );
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AutolabCustomer.primary,
                      foregroundColor: AutolabCustomer.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AutolabCustomer.radiusSm,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Aplicar filtro',
                      style: TextStyle(
                        fontFamily: AutolabCustomer.primaryFont,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseCalendarDay extends StatelessWidget {
  const _PurchaseCalendarDay({
    required this.day,
    this.disabled = false,
    this.outside = false,
    this.selected = false,
    this.today = false,
    this.inRange = false,
  });

  final DateTime day;
  final bool disabled;
  final bool outside;
  final bool selected;
  final bool today;
  final bool inRange;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AutolabCustomer.white
        : disabled || outside
        ? AutolabCustomer.customerSecondaryTextColor(
            context,
          ).withValues(alpha: 0.55)
        : AutolabCustomer.customerTextColor(context);
    final background = selected
        ? AutolabCustomer.primary
        : inRange || today
        ? AutolabCustomer.primary.withValues(alpha: inRange ? 0.18 : 0.14)
        : AutolabCustomer.transparent;

    return Center(
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontFamily: AutolabCustomer.primaryFont,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }

  return value[0].toUpperCase() + value.substring(1);
}
