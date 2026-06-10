// lib/core/date_utils.dart

/// Returns true when [scheduledDate] falls strictly after today's date.
/// Time-of-day is ignored — a meal scheduled for today is always actionable.
bool isFutureMeal(DateTime scheduledDate) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final mealDay = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day);
  return mealDay.isAfter(today);
}
