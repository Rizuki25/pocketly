enum SavingFrequency { daily, weekly, monthly, flexible }

enum SavingsGoalStatus { active, completed, archived }

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentBalance,
    required this.frequency,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.deadline,
    this.category,
    this.archivedAt,
    this.completedAt,
  });

  final String id;
  final String name;
  final int targetAmount;
  final int currentBalance;
  final SavingFrequency frequency;
  final SavingsGoalStatus status;
  final int priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deadline;
  final String? category;
  final DateTime? archivedAt;
  final DateTime? completedAt;

  double get progress =>
      targetAmount == 0 ? 0 : (currentBalance / targetAmount).clamp(0, 1);

  SavingsGoal copyWith({
    String? name,
    int? targetAmount,
    int? currentBalance,
    SavingFrequency? frequency,
    SavingsGoalStatus? status,
    int? priority,
    DateTime? deadline,
    bool clearDeadline = false,
    String? category,
    DateTime? updatedAt,
    DateTime? archivedAt,
    bool clearArchivedAt = false,
    DateTime? completedAt,
  }) {
    return SavingsGoal(
      id: id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentBalance: currentBalance ?? this.currentBalance,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deadline: clearDeadline ? null : deadline ?? this.deadline,
      category: category ?? this.category,
      archivedAt: clearArchivedAt ? null : archivedAt ?? this.archivedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
