extension DateTimeX on DateTime {
  DateTime get atStartOfDay => DateTime(year, month, day);

  DateTime get atEndOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension DurationX on Duration {
  Duration clampDuration(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
