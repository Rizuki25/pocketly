import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/goals/domain/savings_plan_calculator.dart';

void main() {
  const calculator = SavingsPlanCalculator();

  test('recommends rounded-up weekly deposit from remaining amount', () {
    final plan = calculator.calculate(
      _goal(
        target: 1000000,
        balance: 100000,
        frequency: SavingFrequency.weekly,
        deadline: DateTime(2026, 8, 13),
      ),
      asOf: DateTime(2026, 7, 16),
    );

    expect(plan.periodCount, 4);
    expect(plan.recommendedDeposit, 225000);
    expect(plan.remainingAmount, 900000);
  });

  test('does not calculate a fixed deposit without a deadline', () {
    final plan = calculator.calculate(
      _goal(frequency: SavingFrequency.monthly),
      asOf: DateTime(2026, 7, 16),
    );

    expect(plan.periodCount, isNull);
    expect(plan.recommendedDeposit, isNull);
    expect(plan.isOverdue, isFalse);
  });

  test('marks unfinished goal with a past deadline as overdue', () {
    final plan = calculator.calculate(
      _goal(deadline: DateTime(2026, 7, 15)),
      asOf: DateTime(2026, 7, 16),
    );

    expect(plan.isOverdue, isTrue);
    expect(plan.recommendedDeposit, isNull);
  });

  test('completed goal does not require another deposit', () {
    final plan = calculator.calculate(
      _goal(target: 500000, balance: 500000, deadline: DateTime(2026, 7, 15)),
      asOf: DateTime(2026, 7, 16),
    );

    expect(plan.isCompleted, isTrue);
    expect(plan.remainingAmount, 0);
    expect(plan.recommendedDeposit, 0);
  });
}

SavingsGoal _goal({
  int target = 1000000,
  int balance = 0,
  SavingFrequency frequency = SavingFrequency.daily,
  DateTime? deadline,
}) {
  final createdAt = DateTime(2026, 7, 1);
  return SavingsGoal(
    id: 'goal-1',
    name: 'Dana darurat',
    targetAmount: target,
    currentBalance: balance,
    frequency: frequency,
    status: SavingsGoalStatus.active,
    priority: 0,
    createdAt: createdAt,
    updatedAt: createdAt,
    deadline: deadline,
  );
}
