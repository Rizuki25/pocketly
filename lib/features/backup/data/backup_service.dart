import 'dart:typed_data';

import '../../goals/data/goal_repository.dart';
import '../domain/backup_data.dart';
import 'encrypted_backup_codec.dart';

class BackupService {
  const BackupService({
    required this.repository,
    this.codec = const EncryptedBackupCodec(),
  });

  final GoalRepository repository;
  final EncryptedBackupCodec codec;

  Future<Uint8List> create(String password, {DateTime? createdAt}) async {
    final goals = await repository.getAll();
    final transactions = await repository.getTransactions();
    return codec.encrypt(
      BackupData(
        createdAt: createdAt ?? DateTime.now(),
        goals: goals,
        transactions: transactions,
      ),
      password,
    );
  }

  Future<BackupData> inspect(Uint8List bytes, String password) =>
      codec.decrypt(bytes, password);

  Future<void> restore(BackupData data) => repository.replaceAllData(
    goals: data.goals,
    transactions: data.transactions,
  );
}
