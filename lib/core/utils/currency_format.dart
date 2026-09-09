import 'package:intl/intl.dart';

final _colonesFormatter = NumberFormat.currency(
  locale: 'es_CR',
  symbol: '₡',
  decimalDigits: 0,
);

String formatColones(num amount) => _colonesFormatter.format(amount);
