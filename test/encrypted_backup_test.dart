import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/backup/data/backup_service.dart';
import 'package:pocketly/features/backup/data/encrypted_backup_codec.dart';
import 'package:pocketly/features/backup/domain/backup_data.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/transactions/domain/savings_transaction.dart';

void main() {
  const codec = EncryptedBackupCodec(
    parameters: BackupKdfParameters(memory: 64, iterations: 1, parallelism: 1),
    useIsolate: false,
  );
  const password = 'rahasia-backup-ku';

  test('encrypted backup round trip preserves every field', () async {
    final original = _backupData();

    final bytes = await codec.encrypt(original, password);
    final restored = await codec.decrypt(bytes, password);

    expect(restored.createdAt, original.createdAt.toUtc());
    expect(restored.goals.single.id, original.goals.single.id);
    expect(restored.goals.single.name, original.goals.single.name);
    expect(restored.goals.single.targetAmount, 5000000);
    expect(restored.goals.single.currentBalance, 1500000);
    expect(restored.goals.single.deadline, original.goals.single.deadline);
    expect(restored.goals.single.category, 'Keamanan');
    expect(restored.transactions.single.id, 'transaction-1');
    expect(restored.transactions.single.amount, 500000);
    expect(restored.transactions.single.source, 'Gaji');
    expect(restored.transactions.single.note, 'Catatan privat');
  });

  test('encrypted envelope does not expose private backup content', () async {
    final bytes = await codec.encrypt(_backupData(), password);
    final envelope = utf8.decode(bytes);

    expect(envelope, isNot(contains('Dana darurat')));
    expect(envelope, isNot(contains('Catatan privat')));
    expect(envelope, contains('aes-256-gcm'));
    expect(envelope, contains('argon2id'));
  });

  test('wrong password and tampered ciphertext are rejected', () async {
    final bytes = await codec.encrypt(_backupData(), password);

    await expectLater(
      codec.decrypt(bytes, 'kata-sandi-yang-salah'),
      throwsA(isA<BackupException>()),
    );

    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final cipher = envelope['cipher'] as Map<String, dynamic>;
    final ciphertext = base64Url.decode(cipher['ciphertext'] as String);
    ciphertext[0] ^= 1;
    cipher['ciphertext'] = base64UrlEncode(ciphertext);
    final tampered = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));

    await expectLater(
      codec.decrypt(tampered, password),
      throwsA(isA<BackupException>()),
    );
  });

  test('restore replaces goals and transactions together', () async {
    final source = MemoryGoalRepository();
    final data = _backupData();
    await source.replaceAllData(
      goals: data.goals,
      transactions: data.transactions,
    );
    final sourceService = BackupService(repository: source, codec: codec);
    final bytes = await sourceService.create(
      password,
      createdAt: data.createdAt,
    );

    final target = MemoryGoalRepository();
    await target.create(_goal(id: 'old-goal', name: 'Data lama'));
    final targetService = BackupService(repository: target, codec: codec);
    final inspected = await targetService.inspect(bytes, password);
    await targetService.restore(inspected);

    expect((await target.getAll()).map((goal) => goal.id), ['goal-1']);
    expect((await target.getTransactions()).single.id, 'transaction-1');
  });

  test('invalid replacement leaves existing repository untouched', () async {
    final repository = MemoryGoalRepository();
    await repository.create(_goal(id: 'existing', name: 'Tetap ada'));
    final invalid = BackupData(
      createdAt: DateTime.utc(2026, 7, 16),
      goals: [_goal(id: 'new-goal', name: 'Baru')],
      transactions: [_transaction(goalId: 'missing-goal')],
    );

    await expectLater(
      BackupService(repository: repository, codec: codec).restore(invalid),
      throwsFormatException,
    );

    expect((await repository.getAll()).single.id, 'existing');
    expect(await repository.getTransactions(), isEmpty);
  });
}

BackupData _backupData() => BackupData(
  createdAt: DateTime.utc(2026, 7, 16, 9),
  goals: [
    _goal(
      id: 'goal-1',
      name: 'Dana darurat',
      currentBalance: 1500000,
      deadline: DateTime.utc(2027, 7, 16),
      category: 'Keamanan',
    ),
  ],
  transactions: [_transaction(goalId: 'goal-1')],
);

SavingsGoal _goal({
  required String id,
  required String name,
  int currentBalance = 0,
  DateTime? deadline,
  String? category,
}) {
  final now = DateTime.utc(2026, 7, 16, 8);
  return SavingsGoal(
    id: id,
    name: name,
    targetAmount: 5000000,
    currentBalance: currentBalance,
    frequency: SavingFrequency.monthly,
    status: SavingsGoalStatus.active,
    priority: 1,
    createdAt: now,
    updatedAt: now,
    deadline: deadline,
    category: category,
  );
}

SavingsTransaction _transaction({required String goalId}) {
  final now = DateTime.utc(2026, 7, 16, 8, 30);
  return SavingsTransaction(
    id: 'transaction-1',
    goalId: goalId,
    type: SavingsTransactionType.deposit,
    amount: 500000,
    occurredAt: now,
    createdAt: now,
    updatedAt: now,
    source: 'Gaji',
    note: 'Catatan privat',
  );
}
