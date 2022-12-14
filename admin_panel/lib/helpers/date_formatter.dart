import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String toTime(DateTime date) {
    return DateFormat.jm().format(date);
  }

  static String toMonth(DateTime date) {
    return DateFormat.yMMMM().format(date);
  }

  static String toYearMonthDay(DateTime date) {
    return DateFormat.yMMMEd().format(date);
  }

  static String toYearMonth(DateTime date) {
    return DateFormat.yMMMMd().format(date);
  }

  static String toMonthDay(DateTime date) {
    return DateFormat.MMMd().format(date);
  }

  //Saturday, January 3
  static String toWeekDayMonthDay(DateTime date) {
    return DateFormat('EEEE, MMM d').format(date);
  }

  //Sat, Jan 3
  static String toWeekDayMonthDayShort(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  //Jan 3, 2019
  static String toYearMonthDay2(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  static String toWholeDate(DateTime date) {
    return "${toYearMonthDay(date)} | ${toTime(date)}";
  }

  //Mon, Jan 3, 12:00 AM
  static String toWholeDateTime(DateTime date) {
    return "${toWeekDayMonthDayShort(date)} | ${toTime(date)}";
  }

  //Jan 3 | 12:00 AM
  static String toMonthDayTime(DateTime date) {
    return "${toTime(date)} | ${toMonthDay(date)}";
  }
}
