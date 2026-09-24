/// Reusable input validators for OpenAsk forms.
class Validators {
  Validators._();

  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email address is required.';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required.';
    final clean = value.trim();
    if (clean.length < 3) return 'Username must be at least 3 characters.';
    if (clean.length > 30) return 'Username cannot exceed 30 characters.';
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(clean)) {
      return 'Username can only contain letters, numbers, and underscores.';
    }
    return null;
  }

  static String? questionTitle(String? value) {
    if (value == null || value.trim().isEmpty) return 'Question title is required.';
    final len = value.trim().length;
    if (len < 8) return 'Title must be at least 8 characters.';
    if (len > 250) return 'Title cannot exceed 250 characters.';
    return null;
  }

  static String? questionBody(String? value) {
    if (value == null || value.trim().isEmpty) return 'Question details are required.';
    final len = value.trim().length;
    if (len < 15) return 'Please provide more details (at least 15 characters).';
    if (len > 10000) return 'Question body cannot exceed 10,000 characters.';
    return null;
  }

  static String? answerBody(String? value) {
    if (value == null || value.trim().isEmpty) return 'Answer cannot be empty.';
    final len = value.trim().length;
    if (len < 5) return 'Answer must be at least 5 characters.';
    if (len > 10000) return 'Answer cannot exceed 10,000 characters.';
    return null;
  }

  static String? commentBody(String? value) {
    if (value == null || value.trim().isEmpty) return 'Comment cannot be empty.';
    final len = value.trim().length;
    if (len < 2) return 'Comment too short.';
    if (len > 1000) return 'Comment cannot exceed 1,000 characters.';
    return null;
  }
}
