import 'package:flutter/material.dart';

enum ExpiryStatus { safe, nearExpiry, expired }

class ExpiryUtils {
  static ExpiryStatus getExpiryStatus(String expiryDateStr) {
    try {
      final expiryDate = DateTime.parse(expiryDateStr);
      final today = DateTime.now();
      // Reset time portion to compare dates strictly
      final todayDate = DateTime(today.year, today.month, today.day);
      final expDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
      
      final difference = expDate.difference(todayDate).inDays;

      if (difference < 0) {
        return ExpiryStatus.expired;
      } else if (difference < 3) {
        return ExpiryStatus.nearExpiry;
      } else {
        return ExpiryStatus.safe;
      }
    } catch (e) {
      return ExpiryStatus.safe; // Default fallback for parse errors
    }
  }

  static Color getStatusColor(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return Colors.red;
      case ExpiryStatus.nearExpiry:
        return Colors.orange;
      case ExpiryStatus.safe:
        return Colors.green;
    }
  }

  static String getStatusText(ExpiryStatus status) {
    switch (status) {
      case ExpiryStatus.expired:
        return 'Expired';
      case ExpiryStatus.nearExpiry:
        return 'Expiring Soon';
      case ExpiryStatus.safe:
        return 'Safe';
    }
  }
}
