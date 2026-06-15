import 'package:intl/intl.dart';

/// Helpers to format [DateTime] objects for the chat UI.
class DateFormatter {
  DateFormatter._();

  static final _timeFormat = DateFormat('h:mm a');
  static final _dateFormat = DateFormat('MMM d');
  static final _fullFormat = DateFormat('MMM d, y');

  /// Returns "h:mm a" for today, "MMM d" for this year, otherwise "MMM d, y".
  static String chatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return _timeFormat.format(dt);
    if (dt.year == now.year) return _dateFormat.format(dt);
    return _fullFormat.format(dt);
  }

  /// Always returns the short time string (used inside message bubbles).
  static String timeOnly(DateTime dt) => _timeFormat.format(dt);

  /// Returns "Today", "Yesterday", or the date string for section headers.
  static String sectionHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return 'Today';
    if (msgDay == yesterday) return 'Yesterday';
    return _dateFormat.format(dt);
  }
}
