import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../../backup/data/backup_file_gateway.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/domain/savings_goal.dart';
import '../../goals/presentation/goal_form_screen.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/goals_page.dart';
import '../../notifications/data/local_notification_scheduler.dart';
import '../../notifications/data/notification_settings_repository.dart';
import '../../notifications/presentation/notification_settings_screen.dart';
import '../../reports/data/report_export_gateway.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../transactions/domain/savings_transaction.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../../security/presentation/change_pin_screen.dart';
import '../../security/presentation/pin_reauthentication_screen.dart';
import 'widgets/curved_notched_bottom_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
    required this.pinRepository,
    required this.onSecurityChanged,
    required this.onSensitiveScreenChanged,
    required this.goalRepository,
    required this.notificationScheduler,
    required this.notificationSettingsRepository,
    super.key,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;
  final PinAuthRepository pinRepository;
  final Future<void> Function() onSecurityChanged;
  final ValueChanged<bool> onSensitiveScreenChanged;
  final GoalRepository goalRepository;
  final NotificationScheduler notificationScheduler;
  final NotificationSettingsRepository notificationSettingsRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  List<SavingsGoal> _goals = const [];
  bool _loadingGoals = true;
  int _dataRevision = 0;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadGoals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_loadingGoals) {
      unawaited(_syncNotifications(_goals));
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await widget.goalRepository.getAll();
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loadingGoals = false;
        _dataRevision++;
      });
      await _syncNotifications(goals);
    } on Object {
      if (!mounted) return;
      setState(() => _loadingGoals = false);
      _showMessage('Data target belum dapat dibuka.');
    }
  }

  Future<void> _syncNotifications(List<SavingsGoal> goals) async {
    try {
      final settings = await widget.notificationSettingsRepository.read();
      if (settings.enabled) {
        await widget.notificationScheduler.reschedule(goals, settings);
      }
    } on Object {
      // Pengaturan dapat diperbaiki dari layar notifikasi tanpa menghambat data.
    }
  }

  Future<void> _openGoalForm([SavingsGoal? goal]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => GoalFormScreen(
          initialGoal: goal,
          onSave: (value) => goal == null
              ? widget.goalRepository.create(value)
              : widget.goalRepository.update(value),
        ),
      ),
    );
    if (saved == true) {
      await _loadGoals();
      if (mounted) setState(() => _selectedIndex = 1);
    }
  }

  Future<void> _openGoalDetail(SavingsGoal goal) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (detailContext) => GoalDetailScreen(
          goal: goal,
          repository: widget.goalRepository,
          onEdit: _openGoalForm,
          onChanged: _loadGoals,
        ),
      ),
    );
  }

  Future<void> _openTransactionForm(SavingsTransactionType type) async {
    final activeGoals = _goals
        .where((goal) => goal.status != SavingsGoalStatus.archived)
        .toList();
    if (activeGoals.isEmpty) {
      _showMessage('Buat target aktif sebelum mencatat transaksi.');
      return;
    }
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          goals: activeGoals,
          type: type,
          onSave: widget.goalRepository.recordTransaction,
        ),
      ),
    );
    if (saved == true) {
      await _loadGoals();
      if (mounted) {
        setState(() => _selectedIndex = 1);
        _showMessage(
          type == SavingsTransactionType.deposit
              ? 'Setoran tersimpan.'
              : 'Penarikan tersimpan.',
        );
      }
    }
  }

  Future<void> _toggleArchive(SavingsGoal goal) async {
    final archived = goal.status != SavingsGoalStatus.archived;
    try {
      await widget.goalRepository.setArchived(goal.id, archived: archived);
      await _loadGoals();
      _showMessage(archived ? 'Target diarsipkan.' : 'Target dipulihkan.');
    } on Object {
      _showMessage('Status target belum dapat diubah.');
    }
  }

  Future<void> _deleteGoal(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus target?'),
        content: Text(
          'Target “${goal.name}” akan dihapus. Riwayat transaksi nantinya juga akan terdampak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-delete-goal'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.goalRepository.delete(goal.id);
      await _loadGoals();
      _showMessage('Target dihapus.');
    } on Object {
      _showMessage('Target belum dapat dihapus.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openChangePin() async {
    widget.onSensitiveScreenChanged(true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => ChangePinScreen(
            pinRepository: widget.pinRepository,
            onChanged: widget.onSecurityChanged,
          ),
        ),
      );
    } finally {
      widget.onSensitiveScreenChanged(false);
    }
  }

  Future<void> _disableBiometric() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nonaktifkan biometrik?'),
        content: const Text(
          'Setelah dinonaktifkan, Pocketly hanya dapat dibuka menggunakan PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-disable-biometric'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    widget.onSensitiveScreenChanged(true);
    try {
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PinReauthenticationScreen(
            pinRepository: widget.pinRepository,
            title: 'Nonaktifkan biometrik',
            description: 'Masukkan PIN untuk mengonfirmasi perubahan keamanan.',
          ),
        ),
      );
      if (verified == true) await widget.onSecurityChanged();
    } finally {
      widget.onSensitiveScreenChanged(false);
    }
  }

  Future<void> _openBackup() async {
    widget.onSensitiveScreenChanged(true);
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) => BackupScreen(
            service: BackupService(repository: widget.goalRepository),
            fileGateway: const SystemBackupFileGateway(),
            pinRepository: widget.pinRepository,
            onRestored: _loadGoals,
          ),
        ),
      );
    } finally {
      widget.onSensitiveScreenChanged(false);
    }
  }

  Future<void> _openNotificationSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => NotificationSettingsScreen(
          repository: widget.notificationSettingsRepository,
          scheduler: widget.notificationScheduler,
          goals: _goals,
        ),
      ),
    );
  }

  Future<bool> _reauthenticateForReportExport() async {
    widget.onSensitiveScreenChanged(true);
    try {
      final verified = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => PinReauthenticationScreen(
            pinRepository: widget.pinRepository,
            title: 'Ekspor laporan CSV',
            description:
                'Masukkan PIN sebelum membuat file transaksi tanpa enkripsi.',
          ),
        ),
      );
      return verified == true;
    } finally {
      widget.onSensitiveScreenChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        goals: _goals,
        loading: _loadingGoals,
        onCreateGoal: _openGoalForm,
        onNotifications: _openNotificationSettings,
      ),
      GoalsPage(
        goals: _goals,
        loading: _loadingGoals,
        onRefresh: _loadGoals,
        onCreate: _openGoalForm,
        onOpen: _openGoalDetail,
        onEdit: _openGoalForm,
        onArchive: _toggleArchive,
        onDelete: _deleteGoal,
      ),
      _AddPage(
        key: const Key('add-page'),
        onCreateGoal: _openGoalForm,
        onDeposit: () => _openTransactionForm(SavingsTransactionType.deposit),
        onWithdrawal: () =>
            _openTransactionForm(SavingsTransactionType.withdrawal),
      ),
      ReportsScreen(
        key: ValueKey('reports-$_dataRevision'),
        repository: widget.goalRepository,
        goals: _goals,
        exportGateway: const SystemReportExportGateway(),
        reauthenticateForExport: _reauthenticateForReportExport,
      ),
      _ProfilePage(
        biometricEnabled: widget.biometricEnabled,
        onConfigureBiometric: widget.onConfigureBiometric,
        onChangePin: _openChangePin,
        onDisableBiometric: _disableBiometric,
        onBackup: _openBackup,
        onNotifications: _openNotificationSettings,
      ),
    ];

    return Scaffold(
      key: const Key('main-shell'),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: CurvedNotchedBottomBar(
        currentIndex: _selectedIndex,
        onTap: _selectTab,
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard({
    required this.goals,
    required this.loading,
    required this.onCreateGoal,
    required this.onNotifications,
  });

  final List<SavingsGoal> goals;
  final bool loading;
  final VoidCallback onCreateGoal;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final active = goals
        .where((goal) => goal.status != SavingsGoalStatus.archived)
        .toList();
    return SafeArea(
      key: const Key('dashboard-page'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/branding/pocketly_logo.png',
                width: 38,
                height: 38,
              ),
              const SizedBox(width: 10),
              const Text(
                'pocketly',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const Spacer(),
              IconButton(
                key: const Key('dashboard-notification-settings'),
                tooltip: 'Notifikasi',
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 34),
          Text(
            'Selamat datang',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            'Satu target kecil bisa menjadi awal yang berarti.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 30),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (active.isEmpty)
            _EmptyDashboardCard(onCreateGoal: onCreateGoal)
          else
            _DashboardSummary(goals: active, onCreateGoal: onCreateGoal),
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.lock_outline_rounded,
            title: 'Data tetap di perangkatmu',
            description:
                'Target dan transaksi akan disimpan secara lokal di Pocketly.',
          ),
        ],
      ),
    );
  }
}

class _EmptyDashboardCard extends StatelessWidget {
  const _EmptyDashboardCard({required this.onCreateGoal});

  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_outlined,
              size: 46,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada target tabungan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            'Buat target pertamamu untuk mulai mencatat dan melihat perkembangan tabungan.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('dashboard-create-goal'),
            onPressed: onCreateGoal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Buat target pertama'),
          ),
        ],
      ),
    );
  }
}

class _DashboardSummary extends StatelessWidget {
  const _DashboardSummary({required this.goals, required this.onCreateGoal});

  final List<SavingsGoal> goals;
  final VoidCallback onCreateGoal;

  @override
  Widget build(BuildContext context) {
    final total = goals.fold<int>(0, (sum, goal) => sum + goal.currentBalance);
    final priority = goals.firstWhere(
      (goal) => goal.priority > 0,
      orElse: () => goals.first,
    );
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total tabungan'),
          const SizedBox(height: 5),
          Text(
            _rupiah(total),
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontSize: 30),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 15, color: AppColors.primary),
                SizedBox(width: 5),
                Text(
                  'Target Prioritas',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(priority.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: priority.progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: AppColors.background,
            color: AppColors.primary,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onCreateGoal,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Target baru'),
          ),
        ],
      ),
    );
  }
}

String _rupiah(int amount) {
  final source = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write('.');
    buffer.write(source[index]);
  }
  return 'Rp${buffer.toString()}';
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.58),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPage extends StatelessWidget {
  const _AddPage({
    required this.onCreateGoal,
    required this.onDeposit,
    required this.onWithdrawal,
    super.key,
  });

  final VoidCallback onCreateGoal;
  final VoidCallback onDeposit;
  final VoidCallback onWithdrawal;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        children: [
          Text('Tambah', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(
            'Pilih hal yang ingin kamu catat.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 28),
          _ActionCard(
            key: const Key('add-goal-action'),
            icon: Icons.flag_rounded,
            title: 'Target baru',
            description: 'Tentukan tujuan dan rencana tabunganmu.',
            onTap: onCreateGoal,
          ),
          const SizedBox(height: 14),
          _ActionCard(
            key: const Key('add-deposit-action'),
            icon: Icons.south_west_rounded,
            title: 'Setoran',
            description: 'Catat uang yang kamu sisihkan.',
            onTap: onDeposit,
          ),
          const SizedBox(height: 14),
          _ActionCard(
            key: const Key('add-withdrawal-action'),
            icon: Icons.north_east_rounded,
            title: 'Penarikan',
            description: 'Catat uang yang diambil dari target.',
            onTap: onWithdrawal,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.muted),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.58),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
    required this.onChangePin,
    required this.onDisableBiometric,
    required this.onBackup,
    required this.onNotifications,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;
  final VoidCallback onChangePin;
  final VoidCallback onDisableBiometric;
  final VoidCallback onBackup;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      key: const Key('profile-page'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
        children: [
          Text('Profil', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 28),
          _InfoCard(
            icon: Icons.fingerprint_rounded,
            title: biometricEnabled ? 'Biometrik aktif' : 'Biometrik nonaktif',
            description: biometricEnabled
                ? 'Kamu dapat membuka Pocketly dengan biometrik.'
                : 'Aktifkan biometrik untuk membuka Pocketly lebih cepat.',
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            key: const Key('change-pin-action'),
            onPressed: onChangePin,
            icon: const Icon(Icons.password_rounded),
            label: const Text('Ubah PIN'),
          ),
          if (biometricEnabled) ...[
            const SizedBox(height: 10),
            TextButton.icon(
              key: const Key('disable-biometric-action'),
              onPressed: onDisableBiometric,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Nonaktifkan biometrik'),
            ),
          ],
          if (!biometricEnabled) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('configure-biometric'),
              onPressed: onConfigureBiometric,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Text('Aktifkan biometrik'),
            ),
          ],
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi privat',
            description:
                'Atur jadwal, quiet hours, dan isi pesan pada layar kunci.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('notification-settings-action'),
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
            label: const Text('Kelola notifikasi'),
          ),
          const SizedBox(height: 24),
          _InfoCard(
            icon: Icons.enhanced_encryption_outlined,
            title: 'Backup terenkripsi',
            description:
                'Simpan target dan transaksi ke file yang dilindungi kata sandi.',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const Key('backup-settings-action'),
            onPressed: onBackup,
            icon: const Icon(Icons.backup_outlined),
            label: const Text('Kelola backup'),
          ),
          const SizedBox(height: 24),
          const _InfoCard(
            icon: Icons.storage_rounded,
            title: 'Mode lokal',
            description: 'Data Pocketly tersimpan hanya di perangkat ini.',
          ),
        ],
      ),
    );
  }
}
