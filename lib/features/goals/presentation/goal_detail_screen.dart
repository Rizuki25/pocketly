import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/savings_goal.dart';
import '../domain/savings_plan_calculator.dart';

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({
    required this.goal,
    required this.onEdit,
    this.now,
    super.key,
  });

  final SavingsGoal goal;
  final VoidCallback onEdit;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final plan = const SavingsPlanCalculator().calculate(goal, asOf: now);
    return Scaffold(
      key: const Key('goal-detail-screen'),
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
        title: const Text('Detail target'),
        actions: [
          IconButton(
            key: const Key('goal-detail-edit'),
            tooltip: 'Ubah target',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            _ProgressCard(goal: goal),
            const SizedBox(height: 18),
            _PlanCard(goal: goal, plan: plan),
            const SizedBox(height: 18),
            _DetailCard(goal: goal),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final percentage = (goal.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (goal.category != null && goal.category!.trim().isNotEmpty)
            Text(goal.category!, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            goal.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '${_rupiah(goal.currentBalance)} dari ${_rupiah(goal.targetAmount)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: goal.progress,
            minHeight: 10,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: Colors.white24,
            color: Colors.white,
          ),
          const SizedBox(height: 8),
          Text(
            '$percentage% tercapai',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.goal, required this.plan});

  final SavingsGoal goal;
  final SavingsPlan plan;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = _message();
    return _SurfaceCard(
      title: 'Rencana menabung',
      icon: Icons.calculate_outlined,
      child: Container(
        key: const Key('goal-plan-summary'),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description,
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.64),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, String, IconData) _message() {
    if (plan.isCompleted) {
      return (
        'Target sudah tercapai',
        'Hebat, saldo targetmu sudah terpenuhi.',
        Icons.celebration_rounded,
      );
    }
    if (plan.isOverdue) {
      return (
        'Tenggat sudah lewat',
        'Masih tersisa ${_rupiah(plan.remainingAmount)}. Ubah tenggat untuk menghitung rencana baru.',
        Icons.event_busy_outlined,
      );
    }
    if (plan.recommendedDeposit == null) {
      return (
        'Sisa ${_rupiah(plan.remainingAmount)}',
        goal.deadline == null
            ? 'Tambahkan tenggat agar Pocketly dapat menghitung rekomendasi setoran.'
            : 'Frekuensi fleksibel tidak memiliki setoran tetap. Kamu bebas menentukan ritmenya.',
        Icons.savings_outlined,
      );
    }
    return (
      '${_rupiah(plan.recommendedDeposit!)} per ${_periodLabel(goal.frequency)}',
      'Simpan selama ${plan.periodCount} periode untuk menutup sisa ${_rupiah(plan.remainingAmount)} sebelum tenggat.',
      Icons.auto_graph_rounded,
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: 'Informasi target',
      icon: Icons.info_outline_rounded,
      child: Column(
        children: [
          _DetailRow(
            label: 'Frekuensi',
            value: _frequencyLabel(goal.frequency),
          ),
          const Divider(height: 24),
          _DetailRow(
            label: 'Tenggat',
            value: goal.deadline == null
                ? 'Tanpa tenggat'
                : _formatDate(goal.deadline!),
          ),
          const Divider(height: 24),
          _DetailRow(
            label: 'Prioritas',
            value: goal.priority > 0 ? 'Prioritas' : 'Biasa',
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.muted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 9),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.ink.withValues(alpha: 0.58)),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
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

String _periodLabel(SavingFrequency frequency) => switch (frequency) {
  SavingFrequency.daily => 'hari',
  SavingFrequency.weekly => 'minggu',
  SavingFrequency.monthly => 'bulan',
  SavingFrequency.flexible => 'periode',
};

String _frequencyLabel(SavingFrequency frequency) => switch (frequency) {
  SavingFrequency.daily => 'Harian',
  SavingFrequency.weekly => 'Mingguan',
  SavingFrequency.monthly => 'Bulanan',
  SavingFrequency.flexible => 'Fleksibel',
};

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
