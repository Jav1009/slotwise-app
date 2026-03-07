import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat _dateFormatter = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormatter = DateFormat('h:mm a');
  static final DateFormat _dateTimeFormatter = DateFormat('dd MMM yyyy, h:mm a');
  static final DateFormat _apiDateFormatter = DateFormat('yyyy-MM-dd');
  static final DateFormat _apiTimeFormatter = DateFormat('HH:mm');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _dayMonthFormatter = DateFormat('dd MMM');
  static final DateFormat _weekdayFormatter = DateFormat('EEEE');

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } catch (e) {
      return time;
    }
  }

  static String formatTimeFromDateTime(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatApiDate(DateTime date) {
    return _apiDateFormatter.format(date);
  }

  static String formatApiTime(DateTime time) {
    return _apiTimeFormatter.format(time);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  static String formatDayMonth(DateTime date) {
    return _dayMonthFormatter.format(date);
  }

  static String formatWeekday(DateTime date) {
    return _weekdayFormatter.format(date);
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(locale: 'en_US', symbol: '\$');
    return formatter.format(amount);
  }

  static String formatPhoneNumber(String phone) {
    // Remove all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    if (digits.length == 10) {
      // Format as (XXX) XXX-XXXX
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    } else if (digits.length == 11) {
      // Format as +X (XXX) XXX-XXXX
      return '+${digits[0]} (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
    }
    
    return phone;
  }

  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (remainingMinutes == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
    
    return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes min';
  }

  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  static String formatBookingStatus(String status) {
    return status.split('_').map((word) => capitalize(word)).join(' ');
  }

  static String getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }
}