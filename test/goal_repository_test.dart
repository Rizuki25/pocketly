import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/database/database_encryption_key_repository.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';

void main() {
  test('database encryption key is generated once and persisted', () async {
    final store = MemorySecureKeyValueStore();
    final repository = DatabaseEncryptionKeyRepository(store: store);

    final first = await repository.getOrCreateKey();
    final second = await repository.getOrCreateKey();

    expect(second, first);
    expect(first, isNotEmpty);
    expect(store.values, hasLength(1));
  });

  test('corrupted database key is never silently replaced', () async {
    final store = MemorySecureKeyValueStore();
    await store.write('pocketly_database_key_v1', 'rusak');
    final repository = DatabaseEncryptionKeyRepository(store: store);

    expect(repository.getOrCreateKey, throwsStateError);
  });

  test(
    'goal repository supports create update archive restore delete',
    () async {
      final repository = MemoryGoalRepository();
      final now = DateTime(2026, 7, 16);
      final goal = SavingsGoal(
        id: 'goal-1',
        name: 'Dana darurat',
        targetAmount: 12000000,
        currentBalance: 1000000,
        frequency: SavingFrequency.monthly,
        status: SavingsGoalStatus.active,
        priority: 1,
        createdAt: now,
        updatedAt: now,
      );

      await repository.create(goal);
      expect((await repository.getAll()).single.name, 'Dana darurat');

      await repository.update(
        goal.copyWith(
          name: 'Dana aman',
          updatedAt: now.add(const Duration(days: 1)),
        ),
      );
      expect((await repository.getAll()).single.name, 'Dana aman');

      await repository.setArchived(goal.id, archived: true);
      expect(
        (await repository.getAll()).single.status,
        SavingsGoalStatus.archived,
      );

      await repository.setArchived(goal.id, archived: false);
      expect(
        (await repository.getAll()).single.status,
        SavingsGoalStatus.active,
      );

      await repository.delete(goal.id);
      expect(await repository.getAll(), isEmpty);
    },
  );
}
