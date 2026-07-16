import '../../goals/domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';

enum ReportPeriod { weekly, monthly, yearly, custom }

enum ReportTransactionFilter { all, deposits, withdrawals }

class ReportDateRange {
  const ReportDateRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;

  Duration get duration => endExclusive.difference(start);

  ReportDateRange get previous =>
      ReportDateRange(start: start.subtract(duration), endExclusive: start);
}

class ReportQuery {
  const ReportQuery({
    required this.period,
    required this.range,
    required this.transactionFilter,
    this.goalId,
  });

  final ReportPeriod period;
  final ReportDateRange range;
  final ReportTransactionFilter transactionFilter;
  final String? goalId;

  factory ReportQuery.preset(
    ReportPeriod period, {
    DateTime? asOf,
    String? goalId,
    ReportTransactionFilter transactionFilter = ReportTransactionFilter.all,
  }) {
    final now = asOf ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = switch (period) {
      ReportPeriod.weekly => ReportDateRange(
        start: today.subtract(const Duration(days: 6)),
        endExclusive: today.add(const Duration(days: 1)),
      ),
      ReportPeriod.monthly => ReportDateRange(
        start: DateTime(today.year, today.month),
        endExclusive: DateTime(today.year, today.month + 1),
      ),
      ReportPeriod.yearly => ReportDateRange(
        start: DateTime(today.year),
        endExclusive: DateTime(today.year + 1),
      ),
      ReportPeriod.custom => throw ArgumentError(
        'Rentang khusus harus diberikan secara eksplisit.',
      ),
    };
    return ReportQuery(
      period: period,
      range: range,
      transactionFilter: transactionFilter,
      goalId: goalId,
    );
  }

  ReportQuery copyWith({
    ReportPeriod? period,
    ReportDateRange? range,
    ReportTransactionFilter? transactionFilter,
    String? goalId,
    bool clearGoal = false,
  }) => ReportQuery(
    period: period ?? this.period,
    range: range ?? this.range,
    transactionFilter: transactionFilter ?? this.transactionFilter,
    goalId: clearGoal ? null : goalId ?? this.goalId,
  );
}

class ReportResult {
  const ReportResult({
    required this.query,
    required this.transactions,
    required this.totalDeposits,
    required this.totalWithdrawals,
    required this.netChange,
    required this.averageDeposit,
    required this.goalProgress,
    required this.mostConsistentWeekday,
    required this.previousNetChange,
  });

  final ReportQuery query;
  final List<SavingsTransaction> transactions;
  final int totalDeposits;
  final int totalWithdrawals;
  final int netChange;
  final int averageDeposit;
  final double goalProgress;
  final int? mostConsistentWeekday;
  final int previousNetChange;

  int get netDifferenceFromPrevious => netChange - previousNetChange;
}

class ReportCalculator {
  const ReportCalculator();

  ReportResult calculate({
    required List<SavingsGoal> goals,
    required List<SavingsTransaction> transactions,
    required ReportQuery query,
  }) {
    final current = _filter(transactions, query, query.range);
    final previous = _filter(transactions, query, query.range.previous);
    final deposits = current.where(
      (item) => item.type == SavingsTransactionType.deposit,
    );
    final withdrawals = current.where(
      (item) => item.type == SavingsTransactionType.withdrawal,
    );
    final totalDeposits = deposits.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final totalWithdrawals = withdrawals.fold<int>(
      0,
      (sum, item) => sum + item.amount,
    );
    final depositCount = deposits.length;
    final selectedGoals = goals.where(
      (goal) => query.goalId == null || goal.id == query.goalId,
    );
    final targetTotal = selectedGoals.fold<int>(
      0,
      (sum, goal) => sum + goal.targetAmount,
    );
    final balanceTotal = selectedGoals.fold<int>(
      0,
      (sum, goal) => sum + goal.currentBalance,
    );
    final weekdayCounts = <int, int>{};
    for (final transaction in deposits) {
      weekdayCounts.update(
        transaction.occurredAt.weekday,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final consistentDay = weekdayCounts.entries.isEmpty
        ? null
        : (weekdayCounts.entries.toList()..sort((a, b) {
                final byCount = b.value.compareTo(a.value);
                return byCount != 0 ? byCount : a.key.compareTo(b.key);
              }))
              .first
              .key;
    return ReportResult(
      query: query,
      transactions: current,
      totalDeposits: totalDeposits,
      totalWithdrawals: totalWithdrawals,
      netChange: totalDeposits - totalWithdrawals,
      averageDeposit: depositCount == 0 ? 0 : totalDeposits ~/ depositCount,
      goalProgress: targetTotal == 0
          ? 0
          : (balanceTotal / targetTotal).clamp(0, 1),
      mostConsistentWeekday: consistentDay,
      previousNetChange: previous.fold<int>(
        0,
        (sum, item) => sum + item.signedAmount,
      ),
    );
  }

  List<SavingsTransaction> _filter(
    List<SavingsTransaction> source,
    ReportQuery query,
    ReportDateRange range,
  ) {
    final result = source
        .where((item) {
          if (item.occurredAt.isBefore(range.start) ||
              !item.occurredAt.isBefore(range.endExclusive)) {
            return false;
          }
          if (query.goalId != null && item.goalId != query.goalId) return false;
          return switch (query.transactionFilter) {
            ReportTransactionFilter.all => true,
            ReportTransactionFilter.deposits =>
              item.type == SavingsTransactionType.deposit,
            ReportTransactionFilter.withdrawals =>
              item.type == SavingsTransactionType.withdrawal,
          };
        })
        .toList(growable: false);
    result.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return result;
  }
}
