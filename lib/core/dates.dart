/// Calendar-day helpers. Days are keyed as `yyyy-MM-dd` in local time.
String dayKeyOf(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year.toString().padLeft(4, '0')}-${two(d.month)}-${two(d.day)}';
}

/// Strips the time of day.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime parseDayKey(String key) {
  final parts = key.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// e.g. "Tue, 22 Sep".
String shortDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

/// "Today", "Yesterday", "Tomorrow", or [shortDate].
String friendlyDay(DateTime day, {required DateTime today}) {
  final d = dateOnly(day);
  final t = dateOnly(today);
  if (d == t) return 'Today';
  if (d == DateTime(t.year, t.month, t.day - 1)) return 'Yesterday';
  if (d == DateTime(t.year, t.month, t.day + 1)) return 'Tomorrow';
  return shortDate(d);
}
