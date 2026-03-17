import 'package:flutter/material.dart';

class Validators {
  // Email validation with comprehensive regex
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // RFC 5322 compliant email regex
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+"
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    // Additional check for common email providers
    final parts = value.split('@');
    if (parts.length != 2) {
      return 'Invalid email format';
    }
    
    final domain = parts[1];
    if (!domain.contains('.')) {
      return 'Email domain must contain a dot';
    }
    
    return null;
  }

  // Password validation with strength requirements
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 50) {
      return 'Password must not exceed 50 characters';
    }
    
    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character (optional but recommended)
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password should contain at least one special character';
    }
    
    return null;
  }

  // Name validation with comprehensive character set
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 100) {
      return 'Name must not exceed 100 characters';
    }
    
    // Allow letters, spaces, hyphens, apostrophes, dots, and accented characters
    final nameRegex = RegExp(
      r"^[a-zA-ZÀ-ÿ\s'-\.]+$",
      unicode: true,
    );
    
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Phone validation with international support
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove all non-digit characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    
    // Check if it contains only digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Phone number can only contain digits';
    }
    
    // Check length (international standards: 7-15 digits)
    if (cleaned.length < 7) {
      return 'Phone number must be at least 7 digits';
    }
    
    if (cleaned.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Price validation with proper decimal handling
  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
    }
    
    // Allow numbers with up to 2 decimal places, optional leading/trailing zeros
    final priceRegex = RegExp(r'^\d+(\.\d{0,2})?$');
    
    if (!priceRegex.hasMatch(value)) {
      return 'Please enter a valid price (e.g., 25 or 25.99)';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < 0) {
      return 'Price cannot be negative';
    }
    
    if (price > 999999.99) {
      return 'Price exceeds maximum allowed value';
    }
    
    return null;
  }

  // Duration validation
  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
    }
    
    final durationRegex = RegExp(r'^\d+$');
    if (!durationRegex.hasMatch(value)) {
      return 'Please enter a valid duration in minutes';
    }
    
    final duration = int.tryParse(value);
    if (duration == null) {
      return 'Please enter a valid duration';
    }
    
    if (duration < 5) {
      return 'Duration must be at least 5 minutes';
    }
    
    if (duration > 480) {
      return 'Duration must not exceed 8 hours (480 minutes)';
    }
    
    if (duration % 5 != 0) {
      return 'Duration must be in multiples of 5 minutes';
    }
    
    return null;
  }

  // Time validation (24-hour format)
  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    
    // Strict 24-hour time format: HH:MM
    final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):([0-5][0-9])$');
    
    if (!timeRegex.hasMatch(value)) {
      return 'Please enter a valid time in HH:MM format (e.g., 09:30, 14:00)';
    }
    
    final parts = value.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    
    // Validate hour range
    if (hour < 0 || hour > 23) {
      return 'Hour must be between 0 and 23';
    }
    
    // Validate minute range
    if (minute < 0 || minute > 59) {
      return 'Minute must be between 0 and 59';
    }
    
    return null;
  }

  // Date validation (YYYY-MM-DD) with leap year support
  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    // Strict date format: YYYY-MM-DD
    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    
    if (!dateRegex.hasMatch(value)) {
      return 'Please enter a valid date in YYYY-MM-DD format';
    }
    
    try {
      final parts = value.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      // Validate month range
      if (month < 1 || month > 12) {
        return 'Month must be between 1 and 12';
      }
      
      // Validate day range based on month
      final daysInMonth = _getDaysInMonth(year, month);
      if (day < 1 || day > daysInMonth) {
        return 'Day must be between 1 and $daysInMonth for this month';
      }
      
      // Validate actual calendar date
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return 'Invalid date';
      }
      
      // Check if date is in the past
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (date.isBefore(today)) {
        return 'Date cannot be in the past';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }
  
  // Helper method to get days in month (handles leap years)
  static int _getDaysInMonth(int year, int month) {
    if (month == DateTime.february) {
      // Check for leap year
      final isLeapYear = (year % 4 == 0) && (year % 100 != 0 || year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const daysInMonth = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }

  // URL validation with comprehensive regex
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    // Comprehensive URL regex
    final urlRegex = RegExp(
      r'^(https?:\/\/)?' // protocol
      r'(www\.)?' // www
      r'[-a-zA-Z0-9@:%._\+~#=]{1,256}' // domain
      r'\.[a-zA-Z0-9()]{1,6}' // TLD
      r'\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$' // path and query
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL (e.g., https://example.com)';
    }
    
    return null;
  }

  // Notes validation (prevent XSS and inappropriate content)
  static String? validateNotes(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Notes are optional
    }
    
    if (value.length > 500) {
      return 'Notes must not exceed 500 characters';
    }
    
    // Check for potential XSS patterns
    final xssPatterns = [
      RegExp(r'<script', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'onerror=', caseSensitive: false),
      RegExp(r'onload=', caseSensitive: false),
      RegExp(r'onclick=', caseSensitive: false),
      RegExp(r'onmouseover=', caseSensitive: false),
      RegExp(r'alert\(', caseSensitive: false),
      RegExp(r'eval\(', caseSensitive: false),
    ];
    
    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(value)) {
        return 'Notes contain invalid characters';
      }
    }
    
    return null;
  }

  // Integer validation
  static String? validateInteger(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    final intRegex = RegExp(r'^\d+$');
    if (!intRegex.hasMatch(value)) {
      return 'Please enter a valid whole number';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    
    if (max != null && number > max) {
      return 'Value must not exceed $max';
    }
    
    return null;
  }

  // Double validation
  static String? validateDouble(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    
    final doubleRegex = RegExp(r'^\d*\.?\d+$');
    if (!doubleRegex.hasMatch(value)) {
      return 'Please enter a valid number';
    }
    
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (min != null && number < min) {
      return 'Value must be at least $min';
    }
    
    if (max != null && number > max) {
      return 'Value must not exceed $max';
    }
    
    return null;
  }

  // Boolean validation
  static String? validateBoolean(bool? value, String fieldName) {
    if (value == null) {
      return '$fieldName is required';
    }
    return null;
  }

  // List validation
  static String? validateList(List? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please select at least one $fieldName';
    }
    return null;
  }

  // Custom regex validation
  static String? validateRegex(String? value, RegExp regex, String message) {
    if (value == null || value.isEmpty) {
      return message;
    }
    
    if (!regex.hasMatch(value)) {
      return message;
    }
    
    return null;
  }

  // Password strength meter
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength.none;
    }
    
    int score = 0;
    
    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    
    // Character type checks
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;
    
    // No sequential or repeated characters
    if (!RegExp(r'(.)\1{2,}').hasMatch(password)) score++;
    if (!RegExp(r'123|234|345|456|567|678|789|890').hasMatch(password)) score++;
    
    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }
}

enum PasswordStrength {
  none,
  weak,
  medium,
  strong,
  veryStrong;
  
  String get label {
    switch (this) {
      case PasswordStrength.none:
        return 'Enter password';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }
  
  Color getColor(BuildContext context) {
    switch (this) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
      case PasswordStrength.veryStrong:
        return Colors.teal;
    }
  }
}
