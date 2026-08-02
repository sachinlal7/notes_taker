class Helpers {
  const Helpers._();

  static bool isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }
}
