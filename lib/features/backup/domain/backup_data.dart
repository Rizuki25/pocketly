import '../../goals/domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';

class BackupData {
  const BackupData({
    required this.createdAt,
    required this.goals,
    required this.transactions,
  });

  final DateTime createdAt;
  final List<SavingsGoal> goals;
  final List<SavingsTransaction> transactions;
}

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => 'BackupException($message)';
}
