import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/savings_goal.dart';

class GoalsPage extends StatelessWidget {
  const GoalsPage({
    required this.goals,
    required this.loading,
    required this.onRefresh,
    required this.onCreate,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    super.key,
  });

  final List<SavingsGoal> goals;
  final bool loading;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<SavingsGoal> onOpen;
  final ValueChanged<SavingsGoal> onEdit;
  final ValueChanged<SavingsGoal> onArchive;
  final ValueChanged<SavingsGoal> onDelete;

  @override
  Widget build(BuildContext context) {
    final active = goals
        .where((goal) => goal.status != SavingsGoalStatus.archived)
        .toList();
    final archived = goals
        .where((goal) => goal.status == SavingsGoalStatus.archived)
        .toList();

    return SafeArea(
      key: const Key('goals-page'),
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Target',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                ),
                IconButton.filled(
                  key: const Key('goals-create-button'),
                  tooltip: 'Buat target',
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (goals.isEmpty)
              _EmptyGoals(onCreate: onCreate)
            else ...[
              Text('Aktif', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (active.isEmpty)
                const Text('Belum ada target aktif.')
              else
                for (final goal in active) ...[
                  _GoalCard(
                    goal: goal,
                    onOpen: () => onOpen(goal),
                    onEdit: () => onEdit(goal),
                    onArchive: () => onArchive(goal),
                    onDelete: () => onDelete(goal),
                  ),
                  const SizedBox(height: 12),
                ],
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Arsip', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                for (final goal in archived) ...[
                  _GoalCard(
                    goal: goal,
                    onOpen: () => onOpen(goal),
                    onEdit: () => onEdit(goal),
                    onArchive: () => onArchive(goal),
                    onDelete: () => onDelete(goal),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 70),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 64,
            color: AppColors.primary,
          ),
          const SizedBox(height: 18),
          Text(
            'Belum ada target',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Buat target pertamamu untuk mulai menyusun rencana tabungan.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: onCreate, child: const Text('Buat target')),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onOpen,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
  });

  final SavingsGoal goal;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final archived = goal.status == SavingsGoalStatus.archived;
    return Material(
      key: Key('goal-card-${goal.id}'),
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.muted),
      ),
      child: InkWell(
        key: Key('goal-open-${goal.id}'),
        onTap: onOpen,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.flag_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (goal.category != null)
                          Text(
                            goal.category!,
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.55),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    key: Key('goal-menu-${goal.id}'),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                        case 'archive':
                          onArchive();
                        case 'delete':
                          onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                      PopupMenuItem(
                        value: 'archive',
                        child: Text(archived ? 'Pulihkan' : 'Arsipkan'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 9,
                  backgroundColor: AppColors.muted,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _rupiah(goal.currentBalance),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    'dari ${_rupiah(goal.targetAmount)}',
                    style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.58),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
