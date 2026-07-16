import 'dart:math' as math;

import 'savings_goal.dart';

class SavingsPlan {
  const SavingsPlan({
    required this.remainingAmount,
    required this.periodCount,
    required this.recommendedDeposit,
    required this.isOverdue,
    required this.isCompleted,
  });

  final int remainingAmount;
  final int? periodCount;
  final int? recommendedDeposit;
  final bool isOverdue;
  final bool isCompleted;
}

class SavingsPlanCalculator {
  const SavingsPlanCalculator();

  SavingsPlan calculate(SavingsGoal goal, {DateTime? asOf}) {
    final remaining = math.max(0, goal.targetAmount - goal.currentBalance);
    if (remaining == 0) {
      return const SavingsPlan(
        remainingAmount: 0,
        periodCount: 0,
        recommendedDeposit: 0,
        isOverdue: false,
        isCompleted: true,
      );
    }

    final deadline = goal.deadline;
    if (deadline == null || goal.frequency == SavingFrequency.flexible) {
      return SavingsPlan(
        remainingAmount: remaining,
        periodCount: null,
        recommendedDeposit: null,
        isOverdue: false,
        isCompleted: false,
      );
    }

    final today = _dateOnly(asOf ?? DateTime.now());
    final dueDate = _dateOnly(deadline);
    if (dueDate.isBefore(today)) {
      return SavingsPlan(
        remainingAmount: remaining,
        periodCount: 0,
        recommendedDeposit: null,
        isOverdue: true,
        isCompleted: false,
      );
    }

    final daysRemaining = dueDate.difference(today).inDays;
    final periods = switch (goal.frequency) {
      SavingFrequency.daily => math.max(1, daysRemaining),
      SavingFrequency.weekly => math.max(1, (daysRemaining / 7).ceil()),
      SavingFrequency.monthly => math.max(
        1,
        (dueDate.year - today.year) * 12 + dueDate.month - today.month,
      ),
      SavingFrequency.flexible => 1,
    };

    return SavingsPlan(
      remainingAmount: remaining,
      periodCount: periods,
      recommendedDeposit: (remaining / periods).ceil(),
      isOverdue: false,
      isCompleted: false,
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);
