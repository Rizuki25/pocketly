import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../goals/data/goal_repository.dart';
import '../../goals/domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';
import '../data/csv_report_exporter.dart';
import '../data/report_export_gateway.dart';
import '../domain/report_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({
    required this.repository,
    required this.goals,
    required this.exportGateway,
    required this.reauthenticateForExport,
    super.key,
  });

  final GoalRepository repository;
  final List<SavingsGoal> goals;
  final ReportExportGateway exportGateway;
  final Future<bool> Function() reauthenticateForExport;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _calculator = const ReportCalculator();
  ReportQuery _query = ReportQuery.preset(ReportPeriod.monthly);
  List<SavingsTransaction> _transactions = const [];
  bool _loading = true;
  bool _exporting = false;
  String? _message;
  bool _messageIsError = false;

  ReportResult get _report => _calculator.calculate(
    goals: widget.goals,
    transactions: _transactions,
    query: _query,
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final transactions = await widget.repository.getTransactions();
      if (!mounted) return;
      setState(() {
        _transactions = transactions;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messageIsError = true;
        _message = 'Data laporan belum dapat dibuka.';
      });
    }
  }

  Future<void> _selectPeriod(ReportPeriod period) async {
    if (period != ReportPeriod.custom) {
      setState(() {
        _query = ReportQuery.preset(
          period,
          goalId: _query.goalId,
          transactionFilter: _query.transactionFilter,
        );
      });
      return;
    }
    final initial = DateTimeRange(
      start: _query.range.start,
      end: _query.range.endExclusive.subtract(const Duration(days: 1)),
    );
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: initial,
      helpText: 'Pilih rentang laporan',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _query = _query.copyWith(
        period: ReportPeriod.custom,
        range: ReportDateRange(
          start: DateTime(
            selected.start.year,
            selected.start.month,
            selected.start.day,
          ),
          endExclusive: DateTime(
            selected.end.year,
            selected.end.month,
            selected.end.day + 1,
          ),
        ),
      );
    });
  }

  Future<void> _exportCsv() async {
    final report = _report;
    if (_exporting || report.transactions.isEmpty) return;
    final understood = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ekspor CSV tanpa enkripsi?'),
        content: const Text(
          'CSV berisi nama target, tanggal, nominal, sumber/alasan, dan catatan '
          'yang sesuai dengan filter. File dapat dibaca aplikasi lain; pilih '
          'tempat penyimpanan yang aman.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('confirm-plain-csv-export'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    if (understood != true || !mounted) return;
    if (!await widget.reauthenticateForExport() || !mounted) return;
    setState(() {
      _exporting = true;
      _message = null;
    });
    try {
      final bytes = const CsvReportExporter().generate(
        report: report,
        goals: widget.goals,
      );
      final now = DateTime.now();
      final fileName =
          'pocketly-laporan-${now.year}${_two(now.month)}${_two(now.day)}-'
          '${_two(now.hour)}${_two(now.minute)}.csv';
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final shared = await widget.exportGateway.exportCsv(
        bytes: bytes,
        fileName: fileName,
        sharePositionOrigin: origin,
      );
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _messageIsError = false;
        _message = shared
            ? 'CSV laporan siap disimpan.'
            : 'Ekspor CSV dibatalkan.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _exporting = false;
        _messageIsError = true;
        _message = 'CSV laporan belum dapat dibuat.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return SafeArea(
      key: const Key('reports-page'),
      child: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          key: const Key('reports-scroll-view'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Laporan',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Muat ulang laporan',
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Ringkasan dihitung langsung dari riwayat transaksi lokal.',
                style: TextStyle(color: AppColors.ink.withValues(alpha: 0.62)),
              ),
              const SizedBox(height: 20),
              _FilterCard(
                query: _query,
                goals: widget.goals,
                onPeriodChanged: _selectPeriod,
                onGoalChanged: (goalId) => setState(
                  () => _query = _query.copyWith(
                    goalId: goalId,
                    clearGoal: goalId == null,
                  ),
                ),
                onTransactionFilterChanged: (filter) => setState(
                  () => _query = _query.copyWith(transactionFilter: filter),
                ),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _SummaryGrid(report: report),
                const SizedBox(height: 16),
                _InsightCard(report: report),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Transaksi (${report.transactions.length})',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      key: const Key('export-report-csv'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      onPressed: report.transactions.isEmpty || _exporting
                          ? null
                          : _exportCsv,
                      icon: _exporting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.file_download_outlined),
                      label: const Text('CSV'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (report.transactions.isEmpty)
                  const _EmptyReport()
                else
                  ...report.transactions
                      .take(20)
                      .map(
                        (transaction) => _TransactionRow(
                          transaction: transaction,
                          goalName: _goalName(widget.goals, transaction.goalId),
                        ),
                      ),
              ],
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  key: const Key('report-message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _messageIsError ? Colors.redAccent : AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.query,
    required this.goals,
    required this.onPeriodChanged,
    required this.onGoalChanged,
    required this.onTransactionFilterChanged,
  });

  final ReportQuery query;
  final List<SavingsGoal> goals;
  final ValueChanged<ReportPeriod> onPeriodChanged;
  final ValueChanged<String?> onGoalChanged;
  final ValueChanged<ReportTransactionFilter> onTransactionFilterChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.muted),
    ),
    child: Column(
      children: [
        DropdownButtonFormField<ReportPeriod>(
          key: const Key('report-period-filter'),
          isExpanded: true,
          initialValue: query.period,
          decoration: const InputDecoration(labelText: 'Periode'),
          items: ReportPeriod.values
              .map(
                (period) => DropdownMenuItem(
                  value: period,
                  child: Text(_periodLabel(period)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onPeriodChanged(value);
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('report-goal-filter'),
          isExpanded: true,
          initialValue: query.goalId ?? _allGoals,
          decoration: const InputDecoration(labelText: 'Target'),
          items: [
            const DropdownMenuItem(
              value: _allGoals,
              child: Text('Semua target'),
            ),
            ...goals.map(
              (goal) =>
                  DropdownMenuItem(value: goal.id, child: Text(goal.name)),
            ),
          ],
          onChanged: (value) =>
              onGoalChanged(value == null || value == _allGoals ? null : value),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<ReportTransactionFilter>(
          key: const Key('report-transaction-filter'),
          isExpanded: true,
          initialValue: query.transactionFilter,
          decoration: const InputDecoration(labelText: 'Jenis transaksi'),
          items: ReportTransactionFilter.values
              .map(
                (filter) => DropdownMenuItem(
                  value: filter,
                  child: Text(_transactionFilterLabel(filter)),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) onTransactionFilterChanged(value);
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${_date(query.range.start)} – '
            '${_date(query.range.endExclusive.subtract(const Duration(days: 1)))}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.report});

  final ReportResult report;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _MetricCard(
            width: width,
            label: 'Total setoran',
            value: _rupiah(report.totalDeposits),
            color: Colors.green.shade700,
          ),
          _MetricCard(
            width: width,
            label: 'Total penarikan',
            value: _rupiah(report.totalWithdrawals),
            color: Colors.redAccent,
          ),
          _MetricCard(
            width: width,
            label: 'Perubahan bersih',
            value: _signedRupiah(report.netChange),
            color: AppColors.primary,
          ),
          _MetricCard(
            width: width,
            label: 'Rata-rata setoran',
            value: _rupiah(report.averageDeposit),
            color: AppColors.ink,
          ),
        ],
      );
    },
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.muted),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.report});

  final ReportResult report;

  @override
  Widget build(BuildContext context) {
    final difference = report.netDifferenceFromPrevious;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Insight terukur',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'Progres target saat ini: '
            '${(report.goalProgress * 100).toStringAsFixed(1)}%.',
          ),
          const SizedBox(height: 5),
          Text(
            report.mostConsistentWeekday == null
                ? 'Belum ada hari setoran yang dapat dibandingkan.'
                : 'Setoran paling sering tercatat pada '
                      '${_weekday(report.mostConsistentWeekday!)}.',
          ),
          const SizedBox(height: 5),
          Text(
            'Dibanding rentang sebelumnya yang sama panjang, perubahan bersih '
            '${difference == 0
                ? 'tetap'
                : difference > 0
                ? 'naik'
                : 'turun'} '
            '${_rupiah(difference.abs())}.',
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.transaction, required this.goalName});

  final SavingsTransaction transaction;
  final String goalName;

  @override
  Widget build(BuildContext context) {
    final deposit = transaction.type == SavingsTransactionType.deposit;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.muted),
      ),
      child: Row(
        children: [
          Icon(
            deposit ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: deposit ? Colors.green.shade700 : Colors.redAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goalName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(_date(transaction.occurredAt)),
              ],
            ),
          ),
          Text(
            '${deposit ? '+' : '-'}${_rupiah(transaction.amount)}',
            style: TextStyle(
              color: deposit ? Colors.green.shade700 : Colors.redAccent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.muted),
    ),
    child: const Column(
      children: [
        Icon(Icons.receipt_long_outlined, size: 38, color: AppColors.primary),
        SizedBox(height: 10),
        Text('Tidak ada transaksi untuk filter ini.'),
      ],
    ),
  );
}

const _allGoals = '__all_goals__';

String _goalName(List<SavingsGoal> goals, String id) {
  for (final goal in goals) {
    if (goal.id == id) return goal.name;
  }
  return 'Target tidak ditemukan';
}

String _periodLabel(ReportPeriod period) => switch (period) {
  ReportPeriod.weekly => '7 hari terakhir',
  ReportPeriod.monthly => 'Bulan ini',
  ReportPeriod.yearly => 'Tahun ini',
  ReportPeriod.custom => 'Rentang khusus',
};

String _transactionFilterLabel(ReportTransactionFilter filter) =>
    switch (filter) {
      ReportTransactionFilter.all => 'Setoran dan penarikan',
      ReportTransactionFilter.deposits => 'Setoran saja',
      ReportTransactionFilter.withdrawals => 'Penarikan saja',
    };

String _weekday(int weekday) => const [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
][weekday - 1];

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';

String _rupiah(int amount) {
  final source = amount.toString();
  final buffer = StringBuffer('Rp');
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write('.');
    buffer.write(source[index]);
  }
  return buffer.toString();
}

String _signedRupiah(int amount) =>
    '${amount > 0
        ? '+'
        : amount < 0
        ? '-'
        : ''}${_rupiah(amount.abs())}';

String _two(int value) => value.toString().padLeft(2, '0');
