import 'package:intl/intl.dart';

extension DateTimeExtensions on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  static final DateFormat _timeFormat = DateFormat.jms();
  static final DateFormat _dateFormat = DateFormat.yMEd()
      .addPattern("'at'")
      .add_jms();

  String elapsedFromNow() {
    final elapsed = DateTime.now().difference(this);

    if (elapsed.inSeconds < 10) {
      return '刚刚';
    } else if (elapsed.inMinutes < 1) {
      return '1 分钟内';
    } else if (elapsed.inMinutes < 10) {
      return '${elapsed.inMinutes} 分钟前';
    } else {
      if (isSameDay(DateTime.now())) {
        return 'at ${_timeFormat.format(this)}';
      } else {
        return _dateFormat.format(this);
      }
    }
  }
}
