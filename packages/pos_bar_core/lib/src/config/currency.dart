import 'package:intl/intl.dart';

/// ISO 4217 currency code used across POS Bar floor terminals.
const String currencyCode = 'TZS';

final NumberFormat currencyFormat = NumberFormat.simpleCurrency(name: currencyCode);

String formatMoney(num amount) => currencyFormat.format(amount);

String formatMoneyCompact(num amount) => '$currencyCode ${amount.toStringAsFixed(0)}';
