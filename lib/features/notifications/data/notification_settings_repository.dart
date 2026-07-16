import 'dart:convert';

import '../../../core/security/secure_key_value_store.dart';
import '../domain/notification_settings.dart';

class NotificationSettingsRepository {
  const NotificationSettingsRepository({required SecureKeyValueStore store})
    : _store = store;

  static const _key = 'pocketly_notification_settings_v1';
  final SecureKeyValueStore _store;

  Future<NotificationSettings> read() async {
    final encoded = await _store.read(_key);
    if (encoded == null) return NotificationSettings.defaults;
    try {
      final json = jsonDecode(encoded) as Map<String, Object?>;
      if (json['version'] != 1) {
        throw const FormatException('Versi pengaturan tidak didukung.');
      }
      final settings = NotificationSettings(
        enabled: json['enabled']! as bool,
        privacy: NotificationPrivacy.values.byName(json['privacy']! as String),
        reminderMinuteOfDay: json['reminderMinuteOfDay']! as int,
        quietStartMinuteOfDay: json['quietStartMinuteOfDay']! as int,
        quietEndMinuteOfDay: json['quietEndMinuteOfDay']! as int,
      );
      settings.validate();
      return settings;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('Pengaturan notifikasi rusak.');
    }
  }

  Future<void> write(NotificationSettings settings) async {
    settings.validate();
    await _store.write(
      _key,
      jsonEncode({
        'version': 1,
        'enabled': settings.enabled,
        'privacy': settings.privacy.name,
        'reminderMinuteOfDay': settings.reminderMinuteOfDay,
        'quietStartMinuteOfDay': settings.quietStartMinuteOfDay,
        'quietEndMinuteOfDay': settings.quietEndMinuteOfDay,
      }),
    );
  }

  Future<void> clear() => _store.delete(_key);
}
