import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/transactions/domain/savings_transaction.dart';

void main() {
  late MemoryGoalRepository repository;
  late SavingsGoal goal;

  setUp(() async {
    repository = MemoryGoalRepository();
    final now = DateTime(2026, 7, 16);
    goal = SavingsGoal(
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
    await repository.create(goal);
  });

  test('deposit updates balance and history exactly once', () async {
    final transaction = _transaction(
      id: 'transaction-1',
      type: SavingsTransactionType.deposit,
      amount: 500000,
    );

    await repository.recordTransaction(transaction);

    expect((await repository.getAll()).single.currentBalance, 1500000);
    expect(await repository.getTransactions(goalId: goal.id), [transaction]);

    await expectLater(
      repository.recordTransaction(transaction),
      throwsStateError,
    );
    expect((await repository.getAll()).single.currentBalance, 1500000);
  });

  test(
    'withdrawal greater than balance changes neither history nor balance',
    () async {
      await expectLater(
        repository.recordTransaction(
          _transaction(
            id: 'transaction-1',
            type: SavingsTransactionType.withdrawal,
            amount: 1000001,
          ),
        ),
        throwsStateError,
      );

      expect(await repository.getTransactions(goalId: goal.id), isEmpty);
      expect((await repository.getAll()).single.currentBalance, 1000000);
    },
  );

  test(
    'editing transaction reverses old impact before applying new amount',
    () async {
      final transaction = _transaction(
        id: 'transaction-1',
        type: SavingsTransactionType.deposit,
        amount: 500000,
      );
      await repository.recordTransaction(transaction);

      await repository.updateTransaction(
        transaction.copyWith(
          type: SavingsTransactionType.withdrawal,
          amount: 250000,
          updatedAt: DateTime(2026, 7, 17),
        ),
      );

      expect((await repository.getAll()).single.currentBalance, 750000);
      final updated = (await repository.getTransactions()).single;
      expect(updated.type, SavingsTransactionType.withdrawal);
      expect(updated.amount, 250000);
    },
  );

  test('deleting and restoring transaction recalculates balance', () async {
    final transaction = _transaction(
      id: 'transaction-1',
      type: SavingsTransactionType.deposit,
      amount: 500000,
    );
    await repository.recordTransaction(transaction);

    await repository.deleteTransaction(transaction.id);
    expect((await repository.getAll()).single.currentBalance, 1000000);
    expect(await repository.getTransactions(), isEmpty);

    await repository.recordTransaction(transaction);
    expect((await repository.getAll()).single.currentBalance, 1500000);
  });

  test('deleting a goal also deletes its transaction history', () async {
    await repository.recordTransaction(
      _transaction(
        id: 'transaction-1',
        type: SavingsTransactionType.deposit,
        amount: 500000,
      ),
    );

    await repository.delete(goal.id);

    expect(await repository.getTransactions(), isEmpty);
  });
}

SavingsTransaction _transaction({
  required String id,
  required SavingsTransactionType type,
  required int amount,
}) {
  final now = DateTime(2026, 7, 16, 10);
  return SavingsTransaction(
    id: id,
    goalId: 'goal-1',
    type: type,
    amount: amount,
    occurredAt: now,
    createdAt: now,
    updatedAt: now,
  );
}
