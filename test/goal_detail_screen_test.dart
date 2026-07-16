import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/goals/presentation/goal_detail_screen.dart';

void main() {
  testWidgets('shows progress and calculated monthly saving plan', (
    tester,
  ) async {
    final createdAt = DateTime(2026, 7, 1);
    final goal = SavingsGoal(
      id: 'goal-1',
      name: 'Laptop baru',
      targetAmount: 12000000,
      currentBalance: 2000000,
      frequency: SavingFrequency.monthly,
      status: SavingsGoalStatus.active,
      priority: 1,
      createdAt: createdAt,
      updatedAt: createdAt,
      deadline: DateTime(2026, 12, 16),
      category: 'Elektronik',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GoalDetailScreen(
          goal: goal,
          now: DateTime(2026, 7, 16),
          onEdit: () {},
        ),
      ),
    );

    expect(find.byKey(const Key('goal-detail-screen')), findsOneWidget);
    expect(find.text('Laptop baru'), findsOneWidget);
    expect(find.text('17% tercapai'), findsOneWidget);
    expect(find.text('Rp2.000.000 per bulan'), findsOneWidget);
    expect(find.textContaining('5 periode'), findsOneWidget);
  });

  testWidgets('edit action remains available from goal detail', (tester) async {
    var edited = false;
    final createdAt = DateTime(2026, 7, 1);
    final goal = SavingsGoal(
      id: 'goal-1',
      name: 'Dana darurat',
      targetAmount: 1000000,
      currentBalance: 0,
      frequency: SavingFrequency.flexible,
      status: SavingsGoalStatus.active,
      priority: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GoalDetailScreen(goal: goal, onEdit: () => edited = true),
      ),
    );
    await tester.tap(find.byKey(const Key('goal-detail-edit')));

    expect(edited, isTrue);
  });
}
