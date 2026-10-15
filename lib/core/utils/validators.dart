class Validators {
  static String? required(String? value, {String field = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final pattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? positiveNumber(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    final n = double.tryParse(value);
    if (n == null || n < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  static String? positiveInt(String? value, {String field = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field is required';
    }
    final n = int.tryParse(value);
    if (n == null || n < 0) {
      return 'Enter a valid whole number';
    }
    return null;
  }
}
