import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/domain/savings_goal.dart';
import '../../goals/presentation/goal_form_screen.dart';
import '../../goals/presentation/goals_page.dart';
import 'widgets/curved_notched_bottom_bar.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
    required this.goalRepository,
    super.key,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;
  final GoalRepository goalRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  List<SavingsGoal> _goals = const [];
  bool _loadingGoals = true;

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await widget.goalRepository.getAll();
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _loadingGoals = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loadingGoals = false);
      _showMessage('Data target belum dapat dibuka.');
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      _Dashboard(
        goals: _goals,
        loading: _loadingGoals,
        onCreateGoal: _openGoalForm,
      ),
      GoalsPage(
        goals: _goals,
        loading: _loadingGoals,
        onRefresh: _loadGoals,
        onCreate: _openGoalForm,
        onEdit: _openGoalForm,
        onArchive: _toggleArchive,
        onDelete: _deleteGoal,
      ),
      _AddPage(key: const Key('add-page'), onCreateGoal: _openGoalForm),
      const _PlaceholderPage(
        key: Key('reports-page'),
        title: 'Laporan',
        description: 'Ringkasan dan perkembangan tabungan akan tampil di sini.',
        icon: Icons.bar_chart_rounded,
      ),
      _ProfilePage(
        biometricEnabled: widget.biometricEnabled,
        onConfigureBiometric: widget.onConfigureBiometric,
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
  });

  final List<SavingsGoal> goals;
  final bool loading;
  final VoidCallback onCreateGoal;

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
              const IconButton(
                tooltip: 'Notifikasi',
                onPressed: null,
                icon: Icon(Icons.notifications_none_rounded),
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
  const _AddPage({required this.onCreateGoal, super.key});

  final VoidCallback onCreateGoal;

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature akan tersedia pada tahap berikutnya.')),
    );
  }

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
            icon: Icons.south_west_rounded,
            title: 'Setoran',
            description: 'Catat uang yang kamu sisihkan.',
            onTap: () => _showComingSoon(context, 'Setoran'),
          ),
          const SizedBox(height: 14),
          _ActionCard(
            icon: Icons.north_east_rounded,
            title: 'Penarikan',
            description: 'Catat uang yang diambil dari target.',
            onTap: () => _showComingSoon(context, 'Penarikan'),
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

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.description,
    required this.icon,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Icon(icon, size: 58, color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text(
                    'Belum ada data',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;

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
            icon: Icons.storage_rounded,
            title: 'Mode lokal',
            description: 'Data Pocketly tersimpan hanya di perangkat ini.',
          ),
        ],
      ),
    );
  }
}
