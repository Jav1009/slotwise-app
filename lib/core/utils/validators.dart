class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

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
    
    return null;
  }

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
    
    final nameRegex = RegExp(r'^[a-zA-Z\s\'-]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    
    final phoneRegex = RegExp(r'^[\d\s\-\(\)]{7,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePrice(String? value) {
    if (value == null || value.isEmpty) {
      return 'Price is required';
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

  static String? validateDuration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Duration is required';
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

  static String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Time is required';
    }
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!timeRegex.hasMatch(value)) {
      return 'Please enter a valid time in HH:MM format (24-hour)';
    }
    
    return null;
  }

  static String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date is required';
    }
    
    try {
      final parts = value.split('-');
      if (parts.length != 3) {
        return 'Please enter a valid date in YYYY-MM-DD format';
      }
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      if (month < 1 || month > 12) {
        return 'Month must be between 1 and 12';
      }
      
      if (day < 1 || day > 31) {
        return 'Day must be between 1 and 31';
      }
      
      final date = DateTime(year, month, day);
      if (date.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        return 'Date cannot be in the past';
      }
      
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }
}
