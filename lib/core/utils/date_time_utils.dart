class DateTimeUtils {
  const DateTimeUtils._();

  static bool isWithin(Duration duration, DateTime from, DateTime to) {
    return to.difference(from) <= duration;
  }
}
