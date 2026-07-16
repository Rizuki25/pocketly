import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/reports/data/csv_report_exporter.dart';
import 'package:pocketly/features/reports/data/report_export_gateway.dart';
import 'package:pocketly/features/reports/domain/report_models.dart';
import 'package:pocketly/features/reports/presentation/reports_screen.dart';
import 'package:pocketly/features/transactions/domain/savings_transaction.dart';

void main() {
  test('report calculates totals, average, consistency and previous range', () {
    final query = ReportQuery.preset(
      ReportPeriod.monthly,
      asOf: DateTime(2026, 7, 16),
    );
    final result = const ReportCalculator().calculate(
      goals: [_goal(currentBalance: 2500000)],
      transactions: [
        _transaction('d1', SavingsTransactionType.deposit, 100000, 2026, 7, 6),
        _transaction('d2', SavingsTransactionType.deposit, 300000, 2026, 7, 13),
        _transaction(
          'w1',
          SavingsTransactionType.withdrawal,
          50000,
          2026,
          7,
          14,
        ),
        _transaction('old', SavingsTransactionType.deposit, 25000, 2026, 6, 8),
      ],
      query: query,
    );

    expect(result.transactions, hasLength(3));
    expect(result.totalDeposits, 400000);
    expect(result.totalWithdrawals, 50000);
    expect(result.netChange, 350000);
    expect(result.averageDeposit, 200000);
    expect(result.goalProgress, 0.5);
    expect(result.mostConsistentWeekday, DateTime.monday);
    expect(result.previousNetChange, 25000);
    expect(result.netDifferenceFromPrevious, 325000);
  });

  test('transaction and goal filters only include matching rows', () {
    final query = ReportQuery.preset(
      ReportPeriod.yearly,
      asOf: DateTime(2026, 7, 16),
      goalId: 'goal-1',
      transactionFilter: ReportTransactionFilter.withdrawals,
    );
    final result = const ReportCalculator().calculate(
      goals: [_goal()],
      transactions: [
        _transaction(
          'deposit',
          SavingsTransactionType.deposit,
          100000,
          2026,
          7,
          1,
        ),
        _transaction(
          'withdrawal',
          SavingsTransactionType.withdrawal,
          50000,
          2026,
          7,
          2,
        ),
        _transaction(
          'other-goal',
          SavingsTransactionType.withdrawal,
          90000,
          2026,
          7,
          3,
          goalId: 'goal-2',
        ),
      ],
      query: query,
    );

    expect(result.transactions.single.id, 'withdrawal');
    expect(result.totalDeposits, 0);
    expect(result.totalWithdrawals, 50000);
    expect(result.netChange, -50000);
  });

  test(
    'CSV uses BOM, escapes quotes, and neutralizes spreadsheet formulas',
    () {
      final transaction = SavingsTransaction(
        id: 'transaction-1',
        goalId: 'goal-1',
        type: SavingsTransactionType.deposit,
        amount: 100000,
        occurredAt: DateTime(2026, 7, 16, 10),
        createdAt: DateTime(2026, 7, 16, 10),
        updatedAt: DateTime(2026, 7, 16, 10),
        source: '=HYPERLINK("https://example.com")',
        note: 'Catatan, dengan "kutip"',
      );
      final query = ReportQuery.preset(
        ReportPeriod.monthly,
        asOf: DateTime(2026, 7, 16),
      );
      final report = const ReportCalculator().calculate(
        goals: [_goal()],
        transactions: [transaction],
        query: query,
      );

      final bytes = const CsvReportExporter().generate(
        report: report,
        goals: [_goal()],
      );
      expect(bytes.take(3), [0xef, 0xbb, 0xbf]);
      final csv = utf8.decode(bytes.sublist(3));
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, contains('"Catatan, dengan ""kutip"""'));
      expect(csv, contains('"100000"'));
    },
  );

  testWidgets('report screen exports filtered CSV after reauthentication', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(384, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MemoryGoalRepository();
    final goal = _goal(currentBalance: 0);
    await repository.create(goal);
    final now = DateTime.now();
    await repository.recordTransaction(
      SavingsTransaction(
        id: 'transaction-now',
        goalId: goal.id,
        type: SavingsTransactionType.deposit,
        amount: 250000,
        occurredAt: now,
        createdAt: now,
        updatedAt: now,
        source: 'Gaji',
      ),
    );
    final currentGoals = await repository.getAll();
    final gateway = _ReportExportGateway();
    var reauthenticationCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: IndexedStack(
            index: 0,
            children: [
              ReportsScreen(
                repository: repository,
                goals: currentGoals,
                exportGateway: gateway,
                reauthenticateForExport: () async {
                  reauthenticationCalls++;
                  return true;
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rp250.000'), findsWidgets);
    await tester.scrollUntilVisible(
      find.byKey(const Key('export-report-csv')),
      400,
    );
    await tester.tap(find.byKey(const Key('export-report-csv')));
    await tester.pumpAndSettle();
    expect(find.text('Ekspor CSV tanpa enkripsi?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-plain-csv-export')));
    await tester.pumpAndSettle();

    expect(reauthenticationCalls, 1);
    expect(gateway.bytes, isNotNull);
    expect(gateway.fileName, endsWith('.csv'));
    expect(utf8.decode(gateway.bytes!.sublist(3)), contains('Gaji'));
  });
}

SavingsGoal _goal({int currentBalance = 1000000}) {
  final now = DateTime(2026, 1, 1);
  return SavingsGoal(
    id: 'goal-1',
    name: 'Dana darurat',
    targetAmount: 5000000,
    currentBalance: currentBalance,
    frequency: SavingFrequency.monthly,
    status: SavingsGoalStatus.active,
    priority: 1,
    createdAt: now,
    updatedAt: now,
  );
}

SavingsTransaction _transaction(
  String id,
  SavingsTransactionType type,
  int amount,
  int year,
  int month,
  int day, {
  String goalId = 'goal-1',
}) {
  final date = DateTime(year, month, day, 10);
  return SavingsTransaction(
    id: id,
    goalId: goalId,
    type: type,
    amount: amount,
    occurredAt: date,
    createdAt: date,
    updatedAt: date,
  );
}

class _ReportExportGateway implements ReportExportGateway {
  Uint8List? bytes;
  String? fileName;

  @override
  Future<bool> exportCsv({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    this.bytes = bytes;
    this.fileName = fileName;
    return true;
  }
}
