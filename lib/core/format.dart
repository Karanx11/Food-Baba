/// Formats a number without a trailing ".0" when it is whole, e.g. 70 -> "70",
/// 72.5 -> "72.5".
String compactNumber(num value, {int decimals = 1}) {
  return value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(decimals);
}
