import 'package:intl/intl.dart';

abstract final class Formatters {
  static String money(num amount) {
    final n = NumberFormat.decimalPatternDigits(locale: 'en', decimalDigits: 0);
    return '${n.format(amount)} ج.م';
  }

  static String date(DateTime d) => DateFormat('yyyy/MM/dd').format(d);

  static String dateTime(DateTime d) => DateFormat('yyyy/MM/dd - HH:mm').format(d);

  static String period(DateTime d) =>
      DateFormat('MMM yyyy').format(d);
}