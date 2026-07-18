import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/savings_goal.dart';
import '../domain/savings_plan_calculator.dart';

class GoalsPage extends StatefulWidget {
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
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  var _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.goals
        .where((goal) => goal.status != SavingsGoalStatus.archived)
        .toList();
    final archived = widget.goals
        .where((goal) => goal.status == SavingsGoalStatus.archived)
        .toList();
    final visibleGoals = _showArchived ? archived : active;

    return ColoredBox(
      color: const Color(0xFFFCFCFE),
      child: SafeArea(
        key: const Key('goals-page'),
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: widget.onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
            children: [
              const Text(
                'POCKETLY',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      'Target',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontFamily: 'serif',
                        fontSize: 38,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.2,
                      ),
                    ),
                  ),
                  _CreateButton(onPressed: widget.onCreate),
                ],
              ),
              const SizedBox(height: 20),
              _GoalFilter(
                activeCount: active.length,
                archivedCount: archived.length,
                showArchived: _showArchived,
                onChanged: (value) => setState(() => _showArchived = value),
              ),
              const SizedBox(height: 18),
              if (widget.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 72),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (visibleGoals.isEmpty)
                _EmptyGoals(archived: _showArchived, onCreate: widget.onCreate)
              else
                for (final goal in visibleGoals) ...[
                  _GoalCard(goal: goal, onTap: () => _showGoalSheet(goal)),
                  const SizedBox(height: 15),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGoalSheet(SavingsGoal goal) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xFF111827).withValues(alpha: 0.48),
      builder: (sheetContext) => _GoalSummarySheet(
        goal: goal,
        onOpen: () {
          Navigator.pop(sheetContext);
          widget.onOpen(goal);
        },
        onEdit: () {
          Navigator.pop(sheetContext);
          widget.onEdit(goal);
        },
        onArchive: () {
          Navigator.pop(sheetContext);
          widget.onArchive(goal);
        },
        onDelete: () {
          Navigator.pop(sheetContext);
          widget.onDelete(goal);
        },
      ),
    );
  }
}

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IconButton(
        key: const Key('goals-create-button'),
        tooltip: 'Buat target',
        onPressed: onPressed,
        color: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 30),
      ),
    );
  }
}

class _GoalFilter extends StatelessWidget {
  const _GoalFilter({
    required this.activeCount,
    required this.archivedCount,
    required this.showArchived,
    required this.onChanged,
  });

  final int activeCount;
  final int archivedCount;
  final bool showArchived;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterItem(
              key: const Key('goals-active-tab'),
              label: 'Aktif ($activeCount)',
              selected: !showArchived,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _FilterItem(
              key: const Key('goals-archived-tab'),
              label: 'Arsip ($archivedCount)',
              selected: showArchived,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterItem extends StatelessWidget {
  const _FilterItem({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.ink : const Color(0xFF71809B),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals({required this.archived, required this.onCreate});

  final bool archived;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 66),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              archived ? Icons.inventory_2_outlined : Icons.savings_outlined,
              size: 38,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            archived ? 'Arsip masih kosong' : 'Belum ada target',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            archived
                ? 'Target yang kamu arsipkan akan tersimpan di sini.'
                : 'Buat target pertamamu untuk mulai menyusun rencana tabungan.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF71809B), height: 1.45),
          ),
          if (!archived) ...[
            const SizedBox(height: 22),
            FilledButton(onPressed: onCreate, child: const Text('Buat target')),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});

  final SavingsGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final archived = goal.status == SavingsGoalStatus.archived;
    final priority = goal.priority > 0 && !archived;
    final radius = priority ? 27.0 : 20.0;
    return Material(
      key: Key('goal-card-${goal.id}'),
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        key: Key('goal-open-${goal.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: priority
            ? _PriorityGoalCardContent(goal: goal)
            : _RegularGoalCardContent(goal: goal, archived: archived),
      ),
    );
  }
}

class _PriorityGoalCardContent extends StatelessWidget {
  const _PriorityGoalCardContent({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final percentage = (goal.progress * 100).round();
    return Ink(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9562FF), Color(0xFFA46CFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -48,
            right: -42,
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.09),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _GoalIcon(goal: goal, light: true),
                  const Spacer(),
                  const _StatusBadge(label: 'PRIORITAS'),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                goal.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'serif',
                  fontSize: 21,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _goalSubtitle(goal),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _AmountText(goal.currentBalance)),
                  Expanded(
                    child: _AmountText(
                      goal.targetAmount,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.26),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sisa / Tenggat: ${_deadlineSummary(goal)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$percentage% Selesai',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegularGoalCardContent extends StatelessWidget {
  const _RegularGoalCardContent({required this.goal, required this.archived});

  final SavingsGoal goal;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return Ink(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: archived ? const Color(0xFFF8F8FB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9E9ED)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF34405A).withValues(alpha: 0.07),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: archived
                  ? const Color(0xFFF0EFF4)
                  : const Color(0xFFF5EFFF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              _goalIcon(goal),
              color: archived ? const Color(0xFF9B96A8) : AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: archived
                        ? const Color(0xFF777381)
                        : const Color(0xFF202536),
                    fontFamily: 'serif',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  archived
                      ? '${_goalSubtitle(goal)} • Arsip'
                      : _goalSubtitle(goal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF7F8CA3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: goal.progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF0F1F4),
                    color: archived
                        ? const Color(0xFFAAA4B5)
                        : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _rupiah(goal.currentBalance, spaced: true),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: archived
                              ? const Color(0xFF777381)
                              : const Color(0xFF283143),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '/',
                        style: TextStyle(
                          color: Color(0xFFA6B0C0),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _rupiah(goal.targetAmount, spaced: true),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFA0AABB),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.more_vert_rounded,
              color: Color(0xFFC5CDDA),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText(this.amount, {this.textAlign = TextAlign.left});

  final int amount;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      _rupiah(amount, spaced: true),
      textAlign: textAlign,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _GoalSummarySheet extends StatefulWidget {
  const _GoalSummarySheet({
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
  State<_GoalSummarySheet> createState() => _GoalSummarySheetState();
}

class _GoalSummarySheetState extends State<_GoalSummarySheet> {
  late int _simulatedBalance = widget.goal.currentBalance;

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final plan = const SavingsPlanCalculator().calculate(goal);
    final recommended =
        plan.recommendedDeposit ??
        math.max(1, (goal.targetAmount - goal.currentBalance) ~/ 10);
    final simulatedProgress = goal.targetAmount == 0
        ? 0.0
        : (_simulatedBalance / goal.targetAmount).clamp(0.0, 1.0);
    final percentage = (simulatedProgress * 100).round();
    final requiredAmount = math.max(0, goal.targetAmount - _simulatedBalance);
    final archived = goal.status == SavingsGoalStatus.archived;

    return Container(
      key: const Key('goal-summary-sheet'),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          22 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE3EF),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 17),
            Row(
              children: [
                _GoalIcon(goal: goal),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: widget.onOpen,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF20293A),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (goal.category != null)
                          Text(
                            goal.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF91A2BE),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  key: Key('goal-menu-${goal.id}'),
                  tooltip: 'Kelola target',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (value) {
                    switch (value) {
                      case 'open':
                        widget.onOpen();
                      case 'edit':
                        widget.onEdit();
                      case 'archive':
                        widget.onArchive();
                      case 'delete':
                        widget.onDelete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'open',
                      child: Text('Lihat detail'),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Ubah')),
                    PopupMenuItem(
                      value: 'archive',
                      child: Text(archived ? 'Pulihkan' : 'Arsipkan'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
                IconButton.filled(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF2F5F9),
                    foregroundColor: const Color(0xFF8DA0BC),
                    minimumSize: const Size(34, 34),
                    maximumSize: const Size(34, 34),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProgressSummary(
              percentage: percentage,
              balance: _simulatedBalance,
              requiredAmount: requiredAmount,
              progress: simulatedProgress,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    label: 'FREKUENSI',
                    value: _frequencyLabel(goal.frequency),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoBox(
                    label: 'TENGGAT',
                    value: _deadlineSummary(goal),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoBox(
              label: 'SISTEM MENABUNG',
              value: plan.isCompleted
                  ? 'Target sudah tercapai'
                  : 'Setor ${_rupiah(recommended)} secara berkala',
              fullWidth: true,
            ),
            const SizedBox(height: 10),
            _NoteBox(goal: goal, plan: plan),
            if (!archived && !plan.isCompleted) ...[
              const SizedBox(height: 22),
              const Text(
                'SIMULASI MENABUNG LANGSUNG',
                style: TextStyle(
                  color: Color(0xFF8FA1BD),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF7FF),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFEADCFB)),
                      ),
                      child: Text(
                        '+ ${_rupiah(recommended)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      key: const Key('goal-simulate-saving'),
                      onPressed: () => setState(() {
                        _simulatedBalance = math.min(
                          goal.targetAmount,
                          _simulatedBalance + (recommended * 2),
                        );
                      }),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const FittedBox(
                        child: Text(
                          'Simulasi Tabung (x2)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.percentage,
    required this.balance,
    required this.requiredAmount,
    required this.progress,
  });

  final int percentage;
  final int balance;
  final int requiredAmount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFCFDFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: const Color(0xFFF0F3F7),
                    color: AppColors.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: const TextStyle(
                        color: Color(0xFF283246),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Text(
                      'TERCAPAI',
                      style: TextStyle(
                        color: Color(0xFF92A3BE),
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _rupiah(balance),
            style: const TextStyle(
              color: Color(0xFF20293A),
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            requiredAmount == 0
                ? 'Target sudah terpenuhi'
                : 'diperlukan ${_rupiah(requiredAmount)}',
            style: const TextStyle(
              color: Color(0xFF9AAAC2),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  final String label;
  final String value;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9EDF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF97A7BF),
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF344058),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.goal, required this.plan});

  final SavingsGoal goal;
  final SavingsPlan plan;

  @override
  Widget build(BuildContext context) {
    final note = plan.isCompleted
        ? '“Hebat, target ini sudah berhasil kamu capai!”'
        : goal.priority > 0
        ? '“Target prioritasmu—tetap konsisten sampai tercapai.”'
        : '“Langkah kecil yang rutin akan membawa targetmu lebih dekat.”';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFAFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFF0E3FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CATATAN',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: const TextStyle(
              color: Color(0xFF59657B),
              fontSize: 11,
              height: 1.35,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalIcon extends StatelessWidget {
  const _GoalIcon({required this.goal, this.light = false});

  final SavingsGoal goal;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: light ? 42 : 38,
      height: light ? 42 : 38,
      decoration: BoxDecoration(
        color: light
            ? Colors.white.withValues(alpha: 0.17)
            : const Color(0xFFFBF6FF),
        borderRadius: BorderRadius.circular(light ? 13 : 10),
      ),
      child: Icon(
        _goalIcon(goal),
        size: light ? 22 : 19,
        color: light ? Colors.white : AppColors.primary,
      ),
    );
  }
}

IconData _goalIcon(SavingsGoal goal) {
  final text = '${goal.name} ${goal.category ?? ''}'.toLowerCase();
  if (text.contains('laptop') || text.contains('elektronik')) {
    return Icons.laptop_mac_rounded;
  }
  if (text.contains('darurat') || text.contains('finansial')) {
    return Icons.savings_outlined;
  }
  if (text.contains('liburan') || text.contains('travel')) {
    return Icons.flight_takeoff_rounded;
  }
  if (text.contains('rumah')) return Icons.home_rounded;
  if (text.contains('mobil') || text.contains('motor')) {
    return Icons.directions_car_rounded;
  }
  if (text.contains('sekolah') || text.contains('pendidikan')) {
    return Icons.school_rounded;
  }
  return Icons.flag_rounded;
}

String _goalSubtitle(SavingsGoal goal) {
  final parts = <String>[
    if (goal.category != null && goal.category!.trim().isNotEmpty)
      goal.category!.trim(),
    _frequencyLabel(goal.frequency),
  ];
  return parts.join(' • ');
}

String _frequencyLabel(SavingFrequency frequency) {
  return switch (frequency) {
    SavingFrequency.daily => 'Harian',
    SavingFrequency.weekly => 'Mingguan',
    SavingFrequency.monthly => 'Bulanan',
    SavingFrequency.flexible => 'Fleksibel',
  };
}

String _deadlineSummary(SavingsGoal goal) {
  if (goal.progress >= 1 || goal.status == SavingsGoalStatus.completed) {
    return 'Tercapai!';
  }
  final deadline = goal.deadline;
  if (deadline == null) return 'Tanpa tenggat';
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
  return '${months[deadline.month - 1]} ${deadline.year}';
}

String _rupiah(int amount, {bool spaced = false}) {
  final source = amount.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write('.');
    buffer.write(source[index]);
  }
  return 'Rp${spaced ? ' ' : ''}${buffer.toString()}';
}
