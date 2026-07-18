import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/notifications/data/local_notification_scheduler.dart';
import 'package:pocketly/features/notifications/data/notification_settings_repository.dart';
import 'package:pocketly/features/notifications/domain/notification_settings.dart';
import 'package:pocketly/features/notifications/presentation/notification_settings_screen.dart';

void main() {
  test('notification settings persist with hidden amount as default', () async {
    final store = MemorySecureKeyValueStore();
    final repository = NotificationSettingsRepository(store: store);

    final defaults = await repository.read();
    expect(defaults.enabled, isFalse);
    expect(defaults.privacy, NotificationPrivacy.hiddenAmount);
    expect(defaults.reminderMinuteOfDay, 19 * 60);

    final changed = defaults.copyWith(
      enabled: true,
      privacy: NotificationPrivacy.generic,
      reminderMinuteOfDay: 8 * 60 + 30,
    );
    await repository.write(changed);

    final restored = await repository.read();
    expect(restored.enabled, isTrue);
    expect(restored.privacy, NotificationPrivacy.generic);
    expect(restored.reminderMinuteOfDay, 8 * 60 + 30);
  });

  test('quiet hours handle overnight and daytime ranges', () {
    const overnight = NotificationSettings.defaults;
    expect(overnight.isInQuietHours(22 * 60), isTrue);
    expect(overnight.isInQuietHours(6 * 60), isTrue);
    expect(overnight.isInQuietHours(12 * 60), isFalse);

    final daytime = overnight.copyWith(
      quietStartMinuteOfDay: 9 * 60,
      quietEndMinuteOfDay: 17 * 60,
    );
    expect(daytime.isInQuietHours(12 * 60), isTrue);
    expect(daytime.isInQuietHours(18 * 60), isFalse);
  });

  test('privacy copy never leaks disallowed goal data or amount', () {
    final goal = _goal();
    final full = buildSavingsReminderCopy(
      goal,
      NotificationPrivacy.full,
      asOf: DateTime(2026, 7, 16),
    );
    final hidden = buildSavingsReminderCopy(
      goal,
      NotificationPrivacy.hiddenAmount,
      asOf: DateTime(2026, 7, 16),
    );
    final generic = buildSavingsReminderCopy(
      goal,
      NotificationPrivacy.generic,
      asOf: DateTime(2026, 7, 16),
    );

    expect(full.title, contains('Dana darurat'));
    expect(full.body, contains('Rp'));
    expect(hidden.title, contains('Dana darurat'));
    expect(hidden.body, isNot(contains('Rp')));
    expect(generic.title, isNot(contains('Dana darurat')));
    expect(generic.body, isNot(contains('Rp')));
  });

  testWidgets('permission is requested after explanation then settings save', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final repository = NotificationSettingsRepository(store: store);
    final scheduler = _NotificationScheduler(
      permission: NotificationPermissionStatus.granted,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          repository: repository,
          scheduler: scheduler,
          goals: [_goal()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-enabled-switch')));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 0);
    expect(find.text('Aktifkan pengingat?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('notification-permission-continue')));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);

    await tester.scrollUntilVisible(
      find.byKey(const Key('save-notification-settings')),
      300,
    );
    await tester.tap(find.byKey(const Key('save-notification-settings')));
    await tester.pumpAndSettle();

    expect((await repository.read()).enabled, isTrue);
    expect(scheduler.rescheduleCalls, 1);
    expect(scheduler.lastGoals.single.id, 'goal-1');
    expect(find.text('Pengingat berhasil dijadwalkan.'), findsOneWidget);
  });

  testWidgets('denied permission keeps reminders disabled', (tester) async {
    final repository = NotificationSettingsRepository(
      store: MemorySecureKeyValueStore(),
    );
    final scheduler = _NotificationScheduler(
      permission: NotificationPermissionStatus.denied,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          repository: repository,
          scheduler: scheduler,
          goals: [_goal()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-permission-continue')));
    await tester.pumpAndSettle();

    expect((await repository.read()).enabled, isFalse);
    expect(scheduler.rescheduleCalls, 0);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.textContaining('Izin notifikasi ditolak'), findsOneWidget);
  });

  testWidgets('test notification uses currently selected privacy', (
    tester,
  ) async {
    final repository = NotificationSettingsRepository(
      store: MemorySecureKeyValueStore(),
    );
    await repository.write(
      NotificationSettings.defaults.copyWith(enabled: true),
    );
    final scheduler = _NotificationScheduler(
      permission: NotificationPermissionStatus.granted,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: NotificationSettingsScreen(
          repository: repository,
          scheduler: scheduler,
          goals: [_goal()],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('notification-privacy-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lengkap (termasuk nominal)').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('send-test-notification')),
      300,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -80));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('send-test-notification')));
    await tester.pumpAndSettle();

    expect(scheduler.testCalls, 1);
    expect(scheduler.lastTestGoal?.id, 'goal-1');
    expect(scheduler.lastTestSettings?.privacy, NotificationPrivacy.full);
    expect(find.text('Notifikasi uji telah dikirim.'), findsOneWidget);
  });
}

SavingsGoal _goal() {
  final now = DateTime(2026, 7, 16);
  return SavingsGoal(
    id: 'goal-1',
    name: 'Dana darurat',
    targetAmount: 5000000,
    currentBalance: 1000000,
    frequency: SavingFrequency.monthly,
    status: SavingsGoalStatus.active,
    priority: 1,
    createdAt: now,
    updatedAt: now,
    deadline: DateTime(2026, 12, 16),
  );
}

class _NotificationScheduler implements NotificationScheduler {
  _NotificationScheduler({required this.permission});

  final NotificationPermissionStatus permission;
  int permissionRequests = 0;
  int rescheduleCalls = 0;
  int cancelCalls = 0;
  int testCalls = 0;
  List<SavingsGoal> lastGoals = const [];
  SavingsGoal? lastTestGoal;
  NotificationSettings? lastTestSettings;

  @override
  Future<void> cancelAll() async => cancelCalls++;

  @override
  Future<void> initialize() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    permissionRequests++;
    return permission;
  }

  @override
  Future<void> showTestNotification(
    SavingsGoal? goal,
    NotificationSettings settings,
  ) async {
    testCalls++;
    lastTestGoal = goal;
    lastTestSettings = settings;
  }

  @override
  Future<void> reschedule(
    List<SavingsGoal> goals,
    NotificationSettings settings,
  ) async {
    rescheduleCalls++;
    lastGoals = goals;
  }
}
