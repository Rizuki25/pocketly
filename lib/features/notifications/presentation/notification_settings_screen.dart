import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../goals/domain/savings_goal.dart';
import '../data/local_notification_scheduler.dart';
import '../data/notification_settings_repository.dart';
import '../domain/notification_settings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({
    required this.repository,
    required this.scheduler,
    required this.goals,
    super.key,
  });

  final NotificationSettingsRepository repository;
  final NotificationScheduler scheduler;
  final List<SavingsGoal> goals;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  NotificationSettings? _settings;
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await widget.repository.read();
      if (mounted) setState(() => _settings = settings);
    } on Object {
      if (!mounted) return;
      setState(() {
        _settings = NotificationSettings.defaults;
        _message = 'Pengaturan notifikasi tidak dapat dibuka dengan aman.';
        _messageIsError = true;
      });
    }
  }

  Future<void> _toggleEnabled(bool enabled) async {
    final settings = _settings;
    if (settings == null || _busy) return;
    if (!enabled) {
      setState(() => _settings = settings.copyWith(enabled: false));
      return;
    }
    final understood = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aktifkan pengingat?'),
        content: const Text(
          'Pocketly akan mengingatkan jadwal menabung dan target yang '
          'mendekati tenggat. Izin sistem baru diminta setelah kamu memilih '
          'lanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Nanti'),
          ),
          FilledButton(
            key: const Key('notification-permission-continue'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (understood != true || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final permission = await widget.scheduler.requestPermission();
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (permission == NotificationPermissionStatus.granted) {
          _settings = settings.copyWith(enabled: true);
        } else {
          _messageIsError = true;
          _message =
              'Izin notifikasi ditolak. Aktifkan melalui pengaturan sistem '
              'jika ingin memakai pengingat.';
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageIsError = true;
        _message = 'Izin notifikasi belum dapat diperiksa.';
      });
    }
  }

  Future<void> _pickTime(_TimeField field) async {
    final settings = _settings;
    if (settings == null || _busy) return;
    final current = switch (field) {
      _TimeField.reminder => settings.reminderMinuteOfDay,
      _TimeField.quietStart => settings.quietStartMinuteOfDay,
      _TimeField.quietEnd => settings.quietEndMinuteOfDay,
    };
    final selected = await showTimePicker(
      context: context,
      initialTime: _toTime(current),
      helpText: switch (field) {
        _TimeField.reminder => 'Pilih waktu pengingat',
        _TimeField.quietStart => 'Quiet hours dimulai',
        _TimeField.quietEnd => 'Quiet hours berakhir',
      },
    );
    if (selected == null || !mounted) return;
    final minute = selected.hour * 60 + selected.minute;
    setState(() {
      _message = null;
      _settings = switch (field) {
        _TimeField.reminder => settings.copyWith(reminderMinuteOfDay: minute),
        _TimeField.quietStart => settings.copyWith(
          quietStartMinuteOfDay: minute,
        ),
        _TimeField.quietEnd => settings.copyWith(quietEndMinuteOfDay: minute),
      };
    });
  }

  Future<void> _save() async {
    final settings = _settings;
    if (settings == null || _busy) return;
    if (settings.enabled && settings.reminderFallsInQuietHours) {
      setState(() {
        _messageIsError = true;
        _message = 'Waktu pengingat berada di dalam quiet hours.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.write(settings);
      if (settings.enabled) {
        await widget.scheduler.reschedule(widget.goals, settings);
      } else {
        await widget.scheduler.cancelAll();
      }
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageIsError = false;
        _message = settings.enabled
            ? 'Pengingat berhasil dijadwalkan.'
            : 'Pengingat dinonaktifkan.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageIsError = true;
        _message = 'Pengaturan notifikasi belum dapat disimpan.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Scaffold(
      key: const Key('notification-settings-screen'),
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
      ),
      body: settings == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 42,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Pengingat yang menjaga privasi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Secara default nominal tidak ditampilkan. Pocketly '
                          'tidak mengirim data notifikasi ke server.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsCard(
                    child: SwitchListTile.adaptive(
                      key: const Key('notification-enabled-switch'),
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Pengingat tabungan'),
                      subtitle: const Text(
                        'Jadwal mengikuti frekuensi target aktif.',
                      ),
                      value: settings.enabled,
                      onChanged: _busy ? null : _toggleEnabled,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privasi layar kunci',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Pilihan ini menentukan isi pesan yang dijadwalkan.',
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<NotificationPrivacy>(
                          key: const Key('notification-privacy-field'),
                          initialValue: settings.privacy,
                          items: NotificationPrivacy.values
                              .map(
                                (privacy) => DropdownMenuItem(
                                  value: privacy,
                                  child: Text(_privacyLabel(privacy)),
                                ),
                              )
                              .toList(growable: false),
                          onChanged: _busy
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(
                                      () => _settings = settings.copyWith(
                                        privacy: value,
                                      ),
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _SettingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jadwal',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _TimeTile(
                          key: const Key('notification-reminder-time'),
                          label: 'Waktu pengingat',
                          value: _formatTime(
                            context,
                            settings.reminderMinuteOfDay,
                          ),
                          onTap: () => _pickTime(_TimeField.reminder),
                        ),
                        const Divider(),
                        _TimeTile(
                          key: const Key('notification-quiet-start'),
                          label: 'Quiet hours mulai',
                          value: _formatTime(
                            context,
                            settings.quietStartMinuteOfDay,
                          ),
                          onTap: () => _pickTime(_TimeField.quietStart),
                        ),
                        _TimeTile(
                          key: const Key('notification-quiet-end'),
                          label: 'Quiet hours selesai',
                          value: _formatTime(
                            context,
                            settings.quietEndMinuteOfDay,
                          ),
                          onTap: () => _pickTime(_TimeField.quietEnd),
                        ),
                      ],
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _message!,
                      key: const Key('notification-settings-message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _messageIsError
                            ? Colors.redAccent
                            : AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    key: const Key('save-notification-settings'),
                    onPressed: _busy ? null : _save,
                    child: _busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan pengaturan'),
                  ),
                ],
              ),
            ),
    );
  }
}

enum _TimeField { reminder, quietStart, quietEnd }

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.muted),
    ),
    child: child,
  );
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 5),
        const Icon(Icons.schedule_rounded),
      ],
    ),
    onTap: onTap,
  );
}

TimeOfDay _toTime(int minute) =>
    TimeOfDay(hour: minute ~/ 60, minute: minute % 60);

String _formatTime(BuildContext context, int minute) =>
    MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(_toTime(minute), alwaysUse24HourFormat: true);

String _privacyLabel(NotificationPrivacy privacy) => switch (privacy) {
  NotificationPrivacy.full => 'Lengkap (termasuk nominal)',
  NotificationPrivacy.hiddenAmount => 'Sembunyikan nominal',
  NotificationPrivacy.generic => 'Pesan generik',
};
