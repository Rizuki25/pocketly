import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../transactions/domain/savings_transaction.dart';
import '../../transactions/presentation/transaction_form_screen.dart';
import '../data/goal_repository.dart';
import '../domain/savings_goal.dart';
import '../domain/savings_plan_calculator.dart';

class GoalDetailScreen extends StatefulWidget {
  const GoalDetailScreen({
    required this.goal,
    required this.repository,
    required this.onEdit,
    required this.onChanged,
    this.now,
    super.key,
  });

  final SavingsGoal goal;
  final GoalRepository repository;
  final Future<void> Function(SavingsGoal goal) onEdit;
  final Future<void> Function() onChanged;
  final DateTime? now;

  @override
  State<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  late SavingsGoal _goal;
  List<SavingsTransaction> _transactions = const [];
  bool _loadingTransactions = true;
  String? _historyError;

  @override
  void initState() {
    super.initState();
    _goal = widget.goal;
    _reload();
  }

  Future<void> _reload() async {
    try {
      final goals = await widget.repository.getAll();
      final transactions = await widget.repository.getTransactions(
        goalId: widget.goal.id,
      );
      if (!mounted) return;
      final refreshed = goals.where((goal) => goal.id == widget.goal.id);
      setState(() {
        if (refreshed.isNotEmpty) _goal = refreshed.first;
        _transactions = transactions;
        _loadingTransactions = false;
        _historyError = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loadingTransactions = false;
        _historyError = 'Riwayat belum dapat dibuka.';
      });
    }
  }

  Future<void> _openTransaction(
    SavingsTransactionType type, [
    SavingsTransaction? transaction,
  ]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          goals: [_goal],
          initialGoal: _goal,
          type: type,
          initialTransaction: transaction,
          onSave: (value) => transaction == null
              ? widget.repository.recordTransaction(value)
              : widget.repository.updateTransaction(value),
        ),
      ),
    );
    if (saved == true) {
      await widget.onChanged();
      await _reload();
    }
  }

  Future<void> _deleteTransaction(SavingsTransaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus transaksi?'),
        content: const Text(
          'Saldo target akan dihitung ulang setelah transaksi dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-delete-transaction'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTransaction(transaction.id);
      await widget.onChanged();
      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi dihapus.'),
          action: SnackBarAction(
            label: 'Batalkan',
            onPressed: () => _restoreTransaction(transaction),
          ),
        ),
      );
    } on Object {
      if (mounted) _showMessage('Transaksi belum dapat dihapus.');
    }
  }

  Future<void> _restoreTransaction(SavingsTransaction transaction) async {
    try {
      await widget.repository.recordTransaction(transaction);
      await widget.onChanged();
      await _reload();
    } on Object {
      if (mounted) _showMessage('Transaksi tidak dapat dipulihkan.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editGoal() async {
    await widget.onEdit(_goal);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final plan = const SavingsPlanCalculator().calculate(
      _goal,
      asOf: widget.now,
    );
    final archived = _goal.status == SavingsGoalStatus.archived;
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
            onPressed: _editGoal,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            _ProgressCard(goal: _goal),
            const SizedBox(height: 18),
            if (!archived) ...[
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('goal-add-deposit'),
                      onPressed: () =>
                          _openTransaction(SavingsTransactionType.deposit),
                      icon: const Icon(Icons.south_west_rounded),
                      label: const Text('Setoran'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('goal-add-withdrawal'),
                      onPressed: _goal.currentBalance == 0
                          ? null
                          : () => _openTransaction(
                              SavingsTransactionType.withdrawal,
                            ),
                      icon: const Icon(Icons.north_east_rounded),
                      label: const Text('Tarik'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            _PlanCard(goal: _goal, plan: plan),
            const SizedBox(height: 18),
            _TransactionHistoryCard(
              transactions: _transactions,
              loading: _loadingTransactions,
              error: _historyError,
              onRetry: _reload,
              onEdit: (transaction) =>
                  _openTransaction(transaction.type, transaction),
              onDelete: _deleteTransaction,
            ),
            const SizedBox(height: 18),
            _DetailCard(goal: _goal),
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

class _TransactionHistoryCard extends StatelessWidget {
  const _TransactionHistoryCard({
    required this.transactions,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
  });

  final List<SavingsTransaction> transactions;
  final bool loading;
  final String? error;
  final Future<void> Function() onRetry;
  final ValueChanged<SavingsTransaction> onEdit;
  final ValueChanged<SavingsTransaction> onDelete;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      title: 'Riwayat transaksi',
      icon: Icons.receipt_long_outlined,
      child: Builder(
        builder: (context) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (error != null) {
            return Column(
              children: [
                Text(error!),
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
              ],
            );
          }
          if (transactions.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: Text('Belum ada transaksi.')),
            );
          }
          return Column(
            key: const Key('transaction-history'),
            children: [
              for (var index = 0; index < transactions.length; index++) ...[
                _TransactionTile(
                  transaction: transactions[index],
                  onEdit: () => onEdit(transactions[index]),
                  onDelete: () => onDelete(transactions[index]),
                ),
                if (index != transactions.length - 1) const Divider(height: 20),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
  });

  final SavingsTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final deposit = transaction.type == SavingsTransactionType.deposit;
    return Row(
      key: Key('transaction-${transaction.id}'),
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            deposit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deposit ? 'Setoran' : 'Penarikan',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                [
                  _formatDate(transaction.occurredAt),
                  if (transaction.source != null) transaction.source!,
                ].join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              if (transaction.note != null)
                Text(
                  transaction.note!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
            ],
          ),
        ),
        Text(
          '${deposit ? '+' : '-'}${_rupiah(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: deposit ? const Color(0xFF257A4B) : Colors.redAccent,
          ),
        ),
        PopupMenuButton<String>(
          key: Key('transaction-menu-${transaction.id}'),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah')),
            PopupMenuItem(value: 'delete', child: Text('Hapus')),
          ],
        ),
      ],
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
