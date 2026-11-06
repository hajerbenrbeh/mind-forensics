import 'package:shared_preferences/shared_preferences.dart';

/// Manages per-user daily AI request quotas to prevent runaway billing or overuse.
///
/// Section 8 & Rule 6:
/// One user or bug cannot create a large bill.
/// Shows exactly where the limit lives and how to change it.
class DailyUsageLimiter {
  // ===========================================================================
  // CONFIGURATION: CHANGE DAILY LIMIT HERE
  // Adjust this number to increase or decrease how many AI calls a user can
  // make per calendar day.
  // ===========================================================================
  static const int maxDailyRequests = 50;

  static const String _keyDate = 'daily_ai_limit_date';
  static const String _keyCount = 'daily_ai_limit_count';

  /// Standard calm message shown when the daily ceiling is reached.
  static const String limitExceededMessage =
      'You have reached your daily investigation limit ($maxDailyRequests/$maxDailyRequests). '
      'Take time to ground yourself and reflect on your filed cases. You can open new AI inquiries tomorrow.';

  /// Checks if the user is allowed to make an AI request right now.
  static Future<bool> canMakeRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyDate);

    // If it's a new day, reset the counter
    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyCount, 0);
      return true;
    }

    final currentCount = prefs.getInt(_keyCount) ?? 0;
    return currentCount < maxDailyRequests;
  }

  /// Increments the request count by 1 after an AI call is dispatched.
  static Future<void> recordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyDate);

    int count = 0;
    if (savedDate == today) {
      count = prefs.getInt(_keyCount) ?? 0;
    } else {
      await prefs.setString(_keyDate, today);
    }

    await prefs.setInt(_keyCount, count + 1);
  }

  /// Returns how many requests the user has left for today.
  static Future<int> getRemainingRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _getTodayString();
    final savedDate = prefs.getString(_keyDate);

    if (savedDate != today) {
      return maxDailyRequests;
    }

    final currentCount = prefs.getInt(_keyCount) ?? 0;
    final remaining = maxDailyRequests - currentCount;
    return remaining < 0 ? 0 : remaining;
  }

  /// Helper to get current day as YYYY-MM-DD
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Resets usage (useful for testing or subscription resets).
  static Future<void> resetForTesting() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDate);
    await prefs.remove(_keyCount);
  }
}

