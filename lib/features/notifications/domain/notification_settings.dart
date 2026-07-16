enum NotificationPrivacy { full, hiddenAmount, generic }

class NotificationSettings {
  const NotificationSettings({
    required this.enabled,
    required this.privacy,
    required this.reminderMinuteOfDay,
    required this.quietStartMinuteOfDay,
    required this.quietEndMinuteOfDay,
  });

  static const defaults = NotificationSettings(
    enabled: false,
    privacy: NotificationPrivacy.hiddenAmount,
    reminderMinuteOfDay: 19 * 60,
    quietStartMinuteOfDay: 21 * 60,
    quietEndMinuteOfDay: 7 * 60,
  );

  final bool enabled;
  final NotificationPrivacy privacy;
  final int reminderMinuteOfDay;
  final int quietStartMinuteOfDay;
  final int quietEndMinuteOfDay;

  bool get reminderFallsInQuietHours => isInQuietHours(reminderMinuteOfDay);

  bool isInQuietHours(int minuteOfDay) {
    _validateMinute(minuteOfDay);
    if (quietStartMinuteOfDay == quietEndMinuteOfDay) return false;
    if (quietStartMinuteOfDay < quietEndMinuteOfDay) {
      return minuteOfDay >= quietStartMinuteOfDay &&
          minuteOfDay < quietEndMinuteOfDay;
    }
    return minuteOfDay >= quietStartMinuteOfDay ||
        minuteOfDay < quietEndMinuteOfDay;
  }

  NotificationSettings copyWith({
    bool? enabled,
    NotificationPrivacy? privacy,
    int? reminderMinuteOfDay,
    int? quietStartMinuteOfDay,
    int? quietEndMinuteOfDay,
  }) => NotificationSettings(
    enabled: enabled ?? this.enabled,
    privacy: privacy ?? this.privacy,
    reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
    quietStartMinuteOfDay: quietStartMinuteOfDay ?? this.quietStartMinuteOfDay,
    quietEndMinuteOfDay: quietEndMinuteOfDay ?? this.quietEndMinuteOfDay,
  );

  void validate() {
    _validateMinute(reminderMinuteOfDay);
    _validateMinute(quietStartMinuteOfDay);
    _validateMinute(quietEndMinuteOfDay);
    if (enabled && reminderFallsInQuietHours) {
      throw const FormatException(
        'Waktu pengingat tidak boleh berada di dalam quiet hours.',
      );
    }
  }
}

void _validateMinute(int value) {
  if (value < 0 || value >= 24 * 60) {
    throw const FormatException('Waktu notifikasi tidak valid.');
  }
}
