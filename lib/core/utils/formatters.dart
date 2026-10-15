import 'package:intl/intl.dart';

class AppFormatters {
  static String currency(double amount, {String symbol = '\$'}) {
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static String date(DateTime dt) => DateFormat('MMM d, yyyy').format(dt);

  static String dateTime(DateTime dt) =>
      DateFormat('MMM d, yyyy • h:mm a').format(dt);

  static String time(DateTime dt) => DateFormat('h:mm a').format(dt);
}
