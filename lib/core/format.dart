/// Formats a number with at most [decimals] decimal places and no trailing
/// zeros, e.g. 70 -> "70", 72.5 -> "72.5", 1.25 (decimals: 2) -> "1.25".
String compactNumber(num value, {int decimals = 1}) {
  final fixed = value.toStringAsFixed(decimals);
  if (!fixed.contains('.')) return fixed;
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}
