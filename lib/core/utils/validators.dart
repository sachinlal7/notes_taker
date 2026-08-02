class Validators {
  const Validators._();

  static String? requiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value);
    if (requiredError != null) return requiredError;

    final email = value!.trim();
    if (!email.contains('@')) {
      return 'Invalid email address.';
    }

    return null;
  }
}
