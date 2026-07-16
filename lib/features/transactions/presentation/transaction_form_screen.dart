import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatters/rupiah_input_formatter.dart';
import '../../goals/domain/savings_goal.dart';
import '../domain/savings_transaction.dart';

class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({
    required this.goals,
    required this.type,
    required this.onSave,
    this.initialGoal,
    this.initialTransaction,
    super.key,
  });

  final List<SavingsGoal> goals;
  final SavingsGoal? initialGoal;
  final SavingsTransactionType type;
  final SavingsTransaction? initialTransaction;
  final Future<void> Function(SavingsTransaction transaction) onSave;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _sourceController;
  late final TextEditingController _noteController;
  late String? _goalId;
  late DateTime _occurredAt;
  bool _saving = false;
  String? _saveError;

  bool get _editing => widget.initialTransaction != null;

  SavingsTransactionType get _type =>
      widget.initialTransaction?.type ?? widget.type;

  @override
  void initState() {
    super.initState();
    final transaction = widget.initialTransaction;
    _goalId =
        transaction?.goalId ??
        widget.initialGoal?.id ??
        (widget.goals.isEmpty ? null : widget.goals.first.id);
    _amountController = TextEditingController(
      text: transaction == null ? '' : formatRupiahDigits(transaction.amount),
    );
    _sourceController = TextEditingController(text: transaction?.source ?? '');
    _noteController = TextEditingController(text: transaction?.note ?? '');
    _occurredAt = transaction?.occurredAt ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  SavingsGoal? get _selectedGoal {
    for (final goal in widget.goals) {
      if (goal.id == _goalId) return goal;
    }
    return null;
  }

  int get _amount => parseRupiahDigits(_amountController.text);

  int? get _resultingBalance {
    final goal = _selectedGoal;
    if (goal == null) return null;
    final previous = widget.initialTransaction?.signedAmount ?? 0;
    final next = _type == SavingsTransactionType.deposit ? _amount : -_amount;
    return goal.currentBalance - previous + next;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _occurredAt.isAfter(now) ? now : _occurredAt,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (selected != null) setState(() => _occurredAt = selected);
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final goal = _selectedGoal;
    final resultingBalance = _resultingBalance;
    if (goal == null || resultingBalance == null) return;

    if (_type == SavingsTransactionType.withdrawal && resultingBalance < 0) {
      setState(
        () => _saveError = 'Penarikan tidak boleh melebihi saldo target.',
      );
      return;
    }
    if (_type == SavingsTransactionType.deposit &&
        resultingBalance > goal.targetAmount) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Saldo melewati target'),
          content: Text(
            'Saldo ${goal.name} akan menjadi ${_rupiah(resultingBalance)}, '
            'melewati target ${_rupiah(goal.targetAmount)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Periksa lagi'),
            ),
            FilledButton(
              key: const Key('confirm-over-target'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap simpan'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      _saving = true;
      _saveError = null;
    });
    final now = DateTime.now();
    final previous = widget.initialTransaction;
    final transaction = SavingsTransaction(
      id: previous?.id ?? createTransactionId(),
      goalId: goal.id,
      type: _type,
      amount: _amount,
      occurredAt: _occurredAt,
      source: _nullable(_sourceController.text),
      note: _nullable(_noteController.text),
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );
    try {
      await widget.onSave(transaction);
      if (mounted) Navigator.pop(context, true);
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Transaksi belum tersimpan. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deposit = _type == SavingsTransactionType.deposit;
    final resultingBalance = _resultingBalance;
    return Scaffold(
      key: const Key('transaction-form-screen'),
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
        title: Text(
          _editing
              ? 'Ubah ${deposit ? 'setoran' : 'penarikan'}'
              : deposit
              ? 'Tambah setoran'
              : 'Tarik tabungan',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(
                      deposit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 34,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        deposit
                            ? 'Catat uang yang kamu sisihkan ke target.'
                            : 'Lihat dampak penarikan sebelum menyimpannya.',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                key: const Key('transaction-goal-field'),
                initialValue: _goalId,
                decoration: _decoration('Target', Icons.flag_outlined),
                items: widget.goals
                    .map(
                      (goal) => DropdownMenuItem(
                        value: goal.id,
                        child: Text(goal.name),
                      ),
                    )
                    .toList(),
                onChanged: _editing
                    ? null
                    : (value) => setState(() => _goalId = value),
                validator: (value) =>
                    value == null ? 'Pilih target terlebih dahulu.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('transaction-amount-field'),
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                onChanged: (_) => setState(() => _saveError = null),
                decoration: _decoration(
                  'Nominal',
                  Icons.payments_outlined,
                ).copyWith(prefixText: 'Rp '),
                validator: (_) =>
                    _amount <= 0 ? 'Nominal harus lebih dari nol.' : null,
              ),
              const SizedBox(height: 14),
              ListTile(
                key: const Key('transaction-date-picker'),
                onTap: _pickDate,
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFFE9E6F1)),
                ),
                leading: const Icon(
                  Icons.event_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Tanggal'),
                subtitle: Text(_formatDate(_occurredAt)),
                trailing: const Icon(Icons.chevron_right_rounded),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _sourceController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  deposit ? 'Sumber dana (opsional)' : 'Alasan (opsional)',
                  deposit
                      ? Icons.account_balance_wallet_outlined
                      : Icons.help_outline,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                maxLength: 200,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Catatan (opsional)',
                  Icons.notes_rounded,
                ),
              ),
              if (resultingBalance != null) ...[
                const SizedBox(height: 4),
                Container(
                  key: const Key('transaction-balance-preview'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: resultingBalance < 0
                        ? Colors.red.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Text('Saldo setelah transaksi'),
                      const Spacer(),
                      Text(
                        _rupiah(resultingBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: resultingBalance < 0
                              ? Colors.red
                              : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 14),
                Text(
                  _saveError!,
                  key: const Key('transaction-save-error'),
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                key: const Key('transaction-save-button'),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                ),
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon, color: AppColors.primary),
  filled: true,
  fillColor: Colors.white,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: const BorderSide(color: Color(0xFFE9E6F1)),
  ),
);

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _rupiah(int amount) {
  final negative = amount < 0;
  final source = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < source.length; index++) {
    if (index > 0 && (source.length - index) % 3 == 0) buffer.write('.');
    buffer.write(source[index]);
  }
  return '${negative ? '-' : ''}Rp${buffer.toString()}';
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}
