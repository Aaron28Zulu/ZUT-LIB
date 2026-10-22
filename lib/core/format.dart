import 'package:intl/intl.dart';

import 'clock.dart';

final _date = DateFormat('d MMM yyyy');
final _dateShort = DateFormat('EEE d MMM');
final _time = DateFormat('HH:mm');

String formatDate(DateTime d) => _date.format(d.toLocal());

String formatDay(DateTime d) => _dateShort.format(d.toLocal());

String formatTime(DateTime d) => _time.format(d.toLocal());

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatTime(d)}';

/// Relative wording under a week, absolute date otherwise (design conventions).
String formatRelative(DateTime d) {
  final diff = d.difference(Clock.now());
  final future = !diff.isNegative;
  final abs = diff.abs();
  if (abs.inDays >= 7) return formatDate(d);
  String unit;
  if (abs.inDays >= 1) {
    unit = abs.inDays == 1 ? '1 day' : '${abs.inDays} days';
  } else if (abs.inHours >= 1) {
    unit = abs.inHours == 1 ? '1 hour' : '${abs.inHours} hours';
  } else if (abs.inMinutes >= 1) {
    unit = abs.inMinutes == 1 ? '1 minute' : '${abs.inMinutes} minutes';
  } else {
    return 'now';
  }
  return future ? 'in $unit' : '$unit ago';
}

String formatDuration(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return m == 0 ? '${s}s' : '${m}m ${s.toString().padLeft(2, '0')}s';
}
