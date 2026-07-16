import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/transactions/domain/savings_transaction.dart';
import 'package:pocketly/features/transactions/presentation/transaction_form_screen.dart';

void main() {
  testWidgets('deposit form formats amount and submits one transaction', (
    tester,
  ) async {
    SavingsTransaction? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionFormScreen(
          goals: [_goal()],
          type: SavingsTransactionType.deposit,
          onSave: (transaction) async => saved = transaction,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('transaction-amount-field')),
      '500000',
    );
    expect(find.text('500.000'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    expect(find.text('Rp1.500.000'), findsOneWidget);

    expect(find.byKey(const Key('transaction-save-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('transaction-save-button')));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.amount, 500000);
    expect(saved!.type, SavingsTransactionType.deposit);
  });

  testWidgets('withdrawal form rejects amount above current balance', (
    tester,
  ) async {
    var saveCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: TransactionFormScreen(
          goals: [_goal()],
          type: SavingsTransactionType.withdrawal,
          onSave: (_) async => saveCalls++,
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('transaction-amount-field')),
      '1000001',
    );
    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-save-button')));
    await tester.pump();

    expect(
      find.text('Penarikan tidak boleh melebihi saldo target.'),
      findsOneWidget,
    );
    expect(saveCalls, 0);
  });
}

SavingsGoal _goal() {
  final now = DateTime(2026, 7, 16);
  return SavingsGoal(
    id: 'goal-1',
    name: 'Dana darurat',
    targetAmount: 5000000,
    currentBalance: 1000000,
    frequency: SavingFrequency.monthly,
    status: SavingsGoalStatus.active,
    priority: 1,
    createdAt: now,
    updatedAt: now,
  );
}
