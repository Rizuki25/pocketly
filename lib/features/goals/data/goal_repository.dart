import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../core/database/pocketly_database.dart';
import '../domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';

abstract interface class GoalRepository {
  Future<List<SavingsGoal>> getAll();

  Future<void> create(SavingsGoal goal);

  Future<void> update(SavingsGoal goal);

  Future<void> setArchived(String id, {required bool archived});

  Future<void> delete(String id);

  Future<List<SavingsTransaction>> getTransactions({String? goalId});

  Future<void> recordTransaction(SavingsTransaction transaction);

  Future<void> updateTransaction(SavingsTransaction transaction);

  Future<void> deleteTransaction(String id);

  Future<void> replaceAllData({
    required List<SavingsGoal> goals,
    required List<SavingsTransaction> transactions,
  });

  Future<void> close();
}

class SqlCipherGoalRepository implements GoalRepository {
  SqlCipherGoalRepository(this._database);

  final PocketlyDatabase _database;

  @override
  Future<List<SavingsGoal>> getAll() async {
    final rows = await _database.database.query(
      'goals',
      orderBy: 'status ASC, priority DESC, updated_at DESC',
    );
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<void> create(SavingsGoal goal) async {
    await _database.database.insert(
      'goals',
      _toRow(goal),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> update(SavingsGoal goal) async {
    final count = await _database.database.update(
      'goals',
      _toRow(goal),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
    if (count != 1) throw StateError('Target tidak ditemukan.');
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final count = await _database.database.update(
      'goals',
      {
        'status': archived ? 'archived' : 'active',
        'archived_at': archived ? now : null,
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Target tidak ditemukan.');
  }

  @override
  Future<void> delete(String id) async {
    final count = await _database.database.delete(
      'goals',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (count != 1) throw StateError('Target tidak ditemukan.');
  }

  @override
  Future<List<SavingsTransaction>> getTransactions({String? goalId}) async {
    final rows = await _database.database.query(
      'transactions',
      where: goalId == null ? null : 'goal_id = ?',
      whereArgs: goalId == null ? null : [goalId],
      orderBy: 'occurred_at DESC, created_at DESC',
    );
    return rows.map(_transactionFromRow).toList(growable: false);
  }

  @override
  Future<void> recordTransaction(SavingsTransaction transaction) async {
    _validateTransaction(transaction);
    await _database.database.transaction((txn) async {
      final goal = await _goalBalance(txn, transaction.goalId);
      final newBalance = goal.balance + transaction.signedAmount;
      _validateBalance(goal, newBalance, transaction.type);
      await txn.insert(
        'transactions',
        _transactionToRow(transaction),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      await _updateGoalBalance(txn, transaction.goalId, newBalance);
    });
  }

  @override
  Future<void> updateTransaction(SavingsTransaction transaction) async {
    _validateTransaction(transaction);
    await _database.database.transaction((txn) async {
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [transaction.id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Transaksi tidak ditemukan.');
      final previous = _transactionFromRow(rows.single);
      if (previous.goalId != transaction.goalId) {
        throw StateError('Target transaksi tidak dapat dipindahkan.');
      }
      final goal = await _goalBalance(txn, transaction.goalId);
      final newBalance =
          goal.balance - previous.signedAmount + transaction.signedAmount;
      _validateBalance(goal, newBalance, transaction.type);
      final count = await txn.update(
        'transactions',
        _transactionToRow(transaction),
        where: 'id = ?',
        whereArgs: [transaction.id],
      );
      if (count != 1) throw StateError('Transaksi tidak ditemukan.');
      await _updateGoalBalance(txn, transaction.goalId, newBalance);
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _database.database.transaction((txn) async {
      final rows = await txn.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) throw StateError('Transaksi tidak ditemukan.');
      final transaction = _transactionFromRow(rows.single);
      final goal = await _goalBalance(txn, transaction.goalId);
      final newBalance = goal.balance - transaction.signedAmount;
      _validateBalance(goal, newBalance, transaction.type);
      final count = await txn.delete(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (count != 1) throw StateError('Transaksi tidak ditemukan.');
      await _updateGoalBalance(txn, transaction.goalId, newBalance);
    });
  }

  @override
  Future<void> replaceAllData({
    required List<SavingsGoal> goals,
    required List<SavingsTransaction> transactions,
  }) async {
    _validateReplacement(goals, transactions);
    await _database.database.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('goals');
      for (final goal in goals) {
        await txn.insert(
          'goals',
          _toRow(goal),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      for (final transaction in transactions) {
        await txn.insert(
          'transactions',
          _transactionToRow(transaction),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
    });
  }

  Future<_GoalBalance> _goalBalance(
    DatabaseExecutor executor,
    String goalId,
  ) async {
    final rows = await executor.query(
      'goals',
      columns: ['current_balance', 'status'],
      where: 'id = ?',
      whereArgs: [goalId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Target tidak ditemukan.');
    return _GoalBalance(
      balance: rows.single['current_balance']! as int,
      status: SavingsGoalStatus.values.byName(rows.single['status']! as String),
    );
  }

  void _validateBalance(
    _GoalBalance goal,
    int newBalance,
    SavingsTransactionType type,
  ) {
    if (goal.status == SavingsGoalStatus.archived) {
      throw StateError('Target yang diarsipkan tidak dapat diubah.');
    }
    if (newBalance < 0) {
      throw StateError(
        type == SavingsTransactionType.withdrawal
            ? 'Penarikan melebihi saldo target.'
            : 'Perubahan transaksi membuat saldo negatif.',
      );
    }
  }

  Future<void> _updateGoalBalance(
    DatabaseExecutor executor,
    String goalId,
    int balance,
  ) async {
    final count = await executor.update(
      'goals',
      {
        'current_balance': balance,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
    if (count != 1) throw StateError('Target tidak ditemukan.');
  }

  @override
  Future<void> close() => _database.close();

  Map<String, Object?> _toRow(SavingsGoal goal) => {
    'id': goal.id,
    'name': goal.name,
    'target_amount': goal.targetAmount,
    'current_balance': goal.currentBalance,
    'frequency': goal.frequency.name,
    'deadline': goal.deadline?.millisecondsSinceEpoch,
    'category': goal.category,
    'priority': goal.priority,
    'status': goal.status.name,
    'created_at': goal.createdAt.millisecondsSinceEpoch,
    'updated_at': goal.updatedAt.millisecondsSinceEpoch,
    'archived_at': goal.archivedAt?.millisecondsSinceEpoch,
    'completed_at': goal.completedAt?.millisecondsSinceEpoch,
  };

  SavingsGoal _fromRow(Map<String, Object?> row) => SavingsGoal(
    id: row['id']! as String,
    name: row['name']! as String,
    targetAmount: row['target_amount']! as int,
    currentBalance: row['current_balance']! as int,
    frequency: SavingFrequency.values.byName(row['frequency']! as String),
    status: SavingsGoalStatus.values.byName(row['status']! as String),
    priority: row['priority']! as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    deadline: _date(row['deadline']),
    category: row['category'] as String?,
    archivedAt: _date(row['archived_at']),
    completedAt: _date(row['completed_at']),
  );

  DateTime? _date(Object? value) =>
      value == null ? null : DateTime.fromMillisecondsSinceEpoch(value as int);
}

class MemoryGoalRepository implements GoalRepository {
  final Map<String, SavingsGoal> _goals = {};
  final Map<String, SavingsTransaction> _transactions = {};

  @override
  Future<List<SavingsGoal>> getAll() async {
    final goals = _goals.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return goals;
  }

  @override
  Future<void> create(SavingsGoal goal) async {
    if (_goals.containsKey(goal.id)) throw StateError('ID target sudah ada.');
    _goals[goal.id] = goal;
  }

  @override
  Future<void> update(SavingsGoal goal) async {
    if (!_goals.containsKey(goal.id)) {
      throw StateError('Target tidak ditemukan.');
    }
    _goals[goal.id] = goal;
  }

  @override
  Future<void> setArchived(String id, {required bool archived}) async {
    final goal = _goals[id];
    if (goal == null) throw StateError('Target tidak ditemukan.');
    final now = DateTime.now();
    _goals[id] = goal.copyWith(
      status: archived ? SavingsGoalStatus.archived : SavingsGoalStatus.active,
      archivedAt: archived ? now : null,
      clearArchivedAt: !archived,
      updatedAt: now,
    );
  }

  @override
  Future<void> delete(String id) async {
    if (_goals.remove(id) == null) throw StateError('Target tidak ditemukan.');
    _transactions.removeWhere((_, transaction) => transaction.goalId == id);
  }

  @override
  Future<List<SavingsTransaction>> getTransactions({String? goalId}) async {
    final transactions =
        _transactions.values
            .where(
              (transaction) => goalId == null || transaction.goalId == goalId,
            )
            .toList()
          ..sort((a, b) {
            final byDate = b.occurredAt.compareTo(a.occurredAt);
            return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
          });
    return transactions;
  }

  @override
  Future<void> recordTransaction(SavingsTransaction transaction) async {
    _validateMemoryTransaction(transaction);
    if (_transactions.containsKey(transaction.id)) {
      throw StateError('Transaksi sudah tercatat.');
    }
    final goal = _memoryGoal(transaction.goalId);
    final newBalance = goal.currentBalance + transaction.signedAmount;
    _validateMemoryBalance(goal, newBalance, transaction.type);
    _transactions[transaction.id] = transaction;
    _goals[goal.id] = goal.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> updateTransaction(SavingsTransaction transaction) async {
    _validateMemoryTransaction(transaction);
    final previous = _transactions[transaction.id];
    if (previous == null) throw StateError('Transaksi tidak ditemukan.');
    if (previous.goalId != transaction.goalId) {
      throw StateError('Target transaksi tidak dapat dipindahkan.');
    }
    final goal = _memoryGoal(transaction.goalId);
    final newBalance =
        goal.currentBalance - previous.signedAmount + transaction.signedAmount;
    _validateMemoryBalance(goal, newBalance, transaction.type);
    _transactions[transaction.id] = transaction;
    _goals[goal.id] = goal.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final transaction = _transactions[id];
    if (transaction == null) throw StateError('Transaksi tidak ditemukan.');
    final goal = _memoryGoal(transaction.goalId);
    final newBalance = goal.currentBalance - transaction.signedAmount;
    _validateMemoryBalance(goal, newBalance, transaction.type);
    _transactions.remove(id);
    _goals[goal.id] = goal.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> replaceAllData({
    required List<SavingsGoal> goals,
    required List<SavingsTransaction> transactions,
  }) async {
    _validateReplacement(goals, transactions);
    final nextGoals = {for (final goal in goals) goal.id: goal};
    final nextTransactions = {
      for (final transaction in transactions) transaction.id: transaction,
    };
    _goals
      ..clear()
      ..addAll(nextGoals);
    _transactions
      ..clear()
      ..addAll(nextTransactions);
  }

  @override
  Future<void> close() async {}

  SavingsGoal _memoryGoal(String id) {
    final goal = _goals[id];
    if (goal == null) throw StateError('Target tidak ditemukan.');
    return goal;
  }

  void _validateMemoryBalance(
    SavingsGoal goal,
    int balance,
    SavingsTransactionType type,
  ) {
    if (goal.status == SavingsGoalStatus.archived) {
      throw StateError('Target yang diarsipkan tidak dapat diubah.');
    }
    if (balance < 0) {
      throw StateError(
        type == SavingsTransactionType.withdrawal
            ? 'Penarikan melebihi saldo target.'
            : 'Perubahan transaksi membuat saldo negatif.',
      );
    }
  }
}

void _validateTransaction(SavingsTransaction transaction) {
  if (transaction.amount <= 0) {
    throw ArgumentError.value(transaction.amount, 'amount');
  }
}

void _validateReplacement(
  List<SavingsGoal> goals,
  List<SavingsTransaction> transactions,
) {
  final goalIds = <String>{};
  for (final goal in goals) {
    if (goal.id.isEmpty ||
        !goalIds.add(goal.id) ||
        goal.name.trim().isEmpty ||
        goal.targetAmount <= 0 ||
        goal.currentBalance < 0) {
      throw const FormatException('Data target backup tidak valid.');
    }
  }
  final transactionIds = <String>{};
  for (final transaction in transactions) {
    if (transaction.id.isEmpty ||
        !transactionIds.add(transaction.id) ||
        !goalIds.contains(transaction.goalId) ||
        transaction.amount <= 0) {
      throw const FormatException('Data transaksi backup tidak valid.');
    }
  }
}

void _validateMemoryTransaction(SavingsTransaction transaction) =>
    _validateTransaction(transaction);

Map<String, Object?> _transactionToRow(SavingsTransaction transaction) => {
  'id': transaction.id,
  'goal_id': transaction.goalId,
  'type': transaction.type.name,
  'amount': transaction.amount,
  'occurred_at': transaction.occurredAt.millisecondsSinceEpoch,
  'source': transaction.source,
  'note': transaction.note,
  'created_at': transaction.createdAt.millisecondsSinceEpoch,
  'updated_at': transaction.updatedAt.millisecondsSinceEpoch,
};

SavingsTransaction _transactionFromRow(Map<String, Object?> row) =>
    SavingsTransaction(
      id: row['id']! as String,
      goalId: row['goal_id']! as String,
      type: SavingsTransactionType.values.byName(row['type']! as String),
      amount: row['amount']! as int,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(
        row['occurred_at']! as int,
      ),
      source: row['source'] as String?,
      note: row['note'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at']! as int),
    );

class _GoalBalance {
  const _GoalBalance({required this.balance, required this.status});

  final int balance;
  final SavingsGoalStatus status;
}

String createGoalId() {
  final random = Random.secure();
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final suffix = List.generate(
    12,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '$timestamp-$suffix';
}
