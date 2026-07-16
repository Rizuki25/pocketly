import 'dart:convert';
import 'dart:typed_data';

import '../../goals/domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';
import '../domain/report_models.dart';

class CsvReportExporter {
  const CsvReportExporter();

  Uint8List generate({
    required ReportResult report,
    required List<SavingsGoal> goals,
  }) {
    final goalNames = {for (final goal in goals) goal.id: goal.name};
    final rows = <List<String>>[
      ['Tanggal', 'Target', 'Jenis', 'Nominal', 'Sumber/Alasan', 'Catatan'],
      for (final transaction in report.transactions)
        [
          transaction.occurredAt.toIso8601String(),
          goalNames[transaction.goalId] ?? 'Target tidak ditemukan',
          transaction.type == SavingsTransactionType.deposit
              ? 'Setoran'
              : 'Penarikan',
          transaction.amount.toString(),
          transaction.source ?? '',
          transaction.note ?? '',
        ],
    ];
    final csv = rows.map((row) => row.map(_cell).join(',')).join('\r\n');
    return Uint8List.fromList([0xef, 0xbb, 0xbf, ...utf8.encode(csv)]);
  }
}

String _cell(String value) {
  var safe = value;
  if (safe.isNotEmpty && '=+-@'.contains(safe[0])) safe = "'$safe";
  return '"${safe.replaceAll('"', '""')}"';
}
