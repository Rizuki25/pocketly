import 'dart:math';

import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../../core/database/pocketly_database.dart';
import '../domain/savings_goal.dart';

abstract interface class GoalRepository {
  Future<List<SavingsGoal>> getAll();

  Future<void> create(SavingsGoal goal);

  Future<void> update(SavingsGoal goal);

  Future<void> setArchived(String id, {required bool archived});

  Future<void> delete(String id);

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
  }

  @override
  Future<void> close() async {}
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
