import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../goals/domain/savings_goal.dart';
import '../../goals/domain/savings_plan_calculator.dart';
import '../domain/notification_settings.dart';

enum NotificationPermissionStatus { granted, denied }

abstract interface class NotificationScheduler {
  Future<void> initialize();

  Future<NotificationPermissionStatus> requestPermission();

  Future<void> showTestNotification(
    SavingsGoal? goal,
    NotificationSettings settings,
  );

  Future<void> reschedule(
    List<SavingsGoal> goals,
    NotificationSettings settings,
  );

  Future<void> cancelAll();
}

class NotificationCopy {
  const NotificationCopy({required this.title, required this.body});

  final String title;
  final String body;
}

NotificationCopy buildSavingsReminderCopy(
  SavingsGoal goal,
  NotificationPrivacy privacy, {
  DateTime? asOf,
}) {
  if (privacy == NotificationPrivacy.generic) {
    return const NotificationCopy(
      title: 'Waktunya cek rencana tabungan',
      body: 'Buka Pocketly untuk melihat pengingat hari ini.',
    );
  }
  final plan = const SavingsPlanCalculator().calculate(goal, asOf: asOf);
  final title = 'Saatnya menabung untuk ${goal.name}';
  if (privacy == NotificationPrivacy.hiddenAmount ||
      plan.recommendedDeposit == null) {
    return NotificationCopy(
      title: title,
      body: 'Buka Pocketly untuk melihat rencana setoran berikutnya.',
    );
  }
  return NotificationCopy(
    title: title,
    body: 'Rekomendasi setoran ${_rupiah(plan.recommendedDeposit!)}.',
  );
}

class LocalNotificationScheduler implements NotificationScheduler {
  LocalNotificationScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const maxScheduledGoals = 30;
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _refreshLocalTimezone();
    const android = AndroidInitializationSettings('ic_notification');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: darwin),
    );
    _initialized = true;
  }

  Future<void> _refreshLocalTimezone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    await initialize();
    bool? granted;
    if (defaultTargetPlatform == TargetPlatform.android) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return granted == false
        ? NotificationPermissionStatus.denied
        : NotificationPermissionStatus.granted;
  }

  @override
  Future<void> showTestNotification(
    SavingsGoal? goal,
    NotificationSettings settings,
  ) async {
    await initialize();
    final copy = goal == null
        ? const NotificationCopy(
            title: 'Notifikasi uji Pocketly',
            body: 'Pengingat lokal berhasil ditampilkan.',
          )
        : buildSavingsReminderCopy(goal, settings.privacy);
    await _plugin.show(
      id: 0x3fffffff,
      title: copy.title,
      body: copy.body,
      notificationDetails: _details,
      payload: goal == null ? 'test' : 'goal:${goal.id}',
    );
  }

  @override
  Future<void> reschedule(
    List<SavingsGoal> goals,
    NotificationSettings settings,
  ) async {
    await initialize();
    await _refreshLocalTimezone();
    await _plugin.cancelAllPendingNotifications();
    if (!settings.enabled) return;
    settings.validate();
    final eligible = goals
        .where(
          (goal) =>
              goal.status == SavingsGoalStatus.active &&
              goal.currentBalance < goal.targetAmount,
        )
        .take(maxScheduledGoals);
    for (final goal in eligible) {
      await _scheduleSavingsReminder(goal, settings);
      await _scheduleDeadlineReminder(goal, settings);
    }
  }

  @override
  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAllPendingNotifications();
    await _plugin.cancelAll();
  }

  Future<void> _scheduleSavingsReminder(
    SavingsGoal goal,
    NotificationSettings settings,
  ) async {
    final now = tz.TZDateTime.now(tz.local);
    final minute = settings.reminderMinuteOfDay;
    final hour = minute ~/ 60;
    final minuteWithinHour = minute % 60;
    final schedule = switch (goal.frequency) {
      SavingFrequency.daily => _nextDaily(now, hour, minuteWithinHour),
      SavingFrequency.weekly => _nextWeekly(now, hour, minuteWithinHour),
      SavingFrequency.monthly => _nextMonthly(now, hour, minuteWithinHour),
      SavingFrequency.flexible => _nextWeekly(now, hour, minuteWithinHour),
    };
    final match = switch (goal.frequency) {
      SavingFrequency.daily => DateTimeComponents.time,
      SavingFrequency.weekly ||
      SavingFrequency.flexible => DateTimeComponents.dayOfWeekAndTime,
      SavingFrequency.monthly => DateTimeComponents.dayOfMonthAndTime,
    };
    final copy = buildSavingsReminderCopy(goal, settings.privacy);
    await _plugin.zonedSchedule(
      id: _notificationId(goal.id, 0),
      title: copy.title,
      body: copy.body,
      scheduledDate: schedule,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: match,
      payload: 'goal:${goal.id}',
    );
  }

  Future<void> _scheduleDeadlineReminder(
    SavingsGoal goal,
    NotificationSettings settings,
  ) async {
    final deadline = goal.deadline;
    if (deadline == null) return;
    final minute = settings.reminderMinuteOfDay;
    final localDeadline = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      minute ~/ 60,
      minute % 60,
    );
    final scheduled = localDeadline.subtract(const Duration(days: 3));
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    final copy = settings.privacy == NotificationPrivacy.generic
        ? const NotificationCopy(
            title: 'Ada target yang mendekati tenggat',
            body: 'Buka Pocketly untuk meninjau rencana tabunganmu.',
          )
        : NotificationCopy(
            title: '${goal.name} mendekati tenggat',
            body: 'Tinjau progres target ini di Pocketly.',
          );
    await _plugin.zonedSchedule(
      id: _notificationId(goal.id, 1),
      title: copy.title,
      body: copy.body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: 'goal:${goal.id}',
    );
  }
}

const _details = NotificationDetails(
  android: AndroidNotificationDetails(
    'savings_reminders_v1',
    'Pengingat tabungan',
    channelDescription: 'Pengingat jadwal menabung dan tenggat target.',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
    visibility: NotificationVisibility.private,
  ),
  iOS: DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

tz.TZDateTime _nextDaily(tz.TZDateTime now, int hour, int minute) {
  var value = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (!value.isAfter(now)) value = value.add(const Duration(days: 1));
  return value;
}

tz.TZDateTime _nextWeekly(tz.TZDateTime now, int hour, int minute) {
  var value = _nextDaily(now, hour, minute);
  value = value.add(Duration(days: (DateTime.monday - value.weekday) % 7));
  if (!value.isAfter(now)) value = value.add(const Duration(days: 7));
  return value;
}

tz.TZDateTime _nextMonthly(tz.TZDateTime now, int hour, int minute) {
  var value = tz.TZDateTime(tz.local, now.year, now.month, 1, hour, minute);
  if (!value.isAfter(now)) {
    value = tz.TZDateTime(tz.local, now.year, now.month + 1, 1, hour, minute);
  }
  return value;
}

int _notificationId(String goalId, int suffix) {
  var hash = 0x811c9dc5;
  for (final unit in goalId.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x3fffffff;
  }
  return math.min(0x7ffffffe, hash * 2 + suffix);
}

String _rupiah(int amount) {
  final source = amount.toString();
  final result = StringBuffer('Rp');
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) result.write('.');
    result.write(source[index]);
  }
  return result.toString();
}
