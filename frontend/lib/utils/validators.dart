class Validators {
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username cannot be empty';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters';
    }
    if (value.length > 20) {
      return 'Username must be less than 20 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'Username can only contain letters, numbers, _ and -';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value.length > 128) {
      return 'Password is too long';
    }
    return null;
  }

  static String? validatePasswordMatch(String? password, String? confirm) {
    if (password != confirm) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Group name cannot be empty';
    }
    if (value.length < 2) {
      return 'Group name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Group name must be less than 50 characters';
    }
    return null;
  }

  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (value.length > 5000) {
      return 'Message is too long';
    }
    return null;
  }
}
