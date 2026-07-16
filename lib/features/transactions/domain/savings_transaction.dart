import 'dart:math';

enum SavingsTransactionType { deposit, withdrawal }

class SavingsTransaction {
  const SavingsTransaction({
    required this.id,
    required this.goalId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.source,
    this.note,
  });

  final String id;
  final String goalId;
  final SavingsTransactionType type;
  final int amount;
  final DateTime occurredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? source;
  final String? note;

  int get signedAmount =>
      type == SavingsTransactionType.deposit ? amount : -amount;

  SavingsTransaction copyWith({
    SavingsTransactionType? type,
    int? amount,
    DateTime? occurredAt,
    DateTime? updatedAt,
    String? source,
    bool clearSource = false,
    String? note,
    bool clearNote = false,
  }) {
    return SavingsTransaction(
      id: id,
      goalId: goalId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: clearSource ? null : source ?? this.source,
      note: clearNote ? null : note ?? this.note,
    );
  }
}

String createTransactionId() {
  final random = Random.secure();
  final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final suffix = List.generate(
    12,
    (_) => random.nextInt(16).toRadixString(16),
  ).join();
  return '$timestamp-$suffix';
}
