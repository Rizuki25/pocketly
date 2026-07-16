import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../data/goal_repository.dart';
import '../domain/savings_goal.dart';

class GoalFormScreen extends StatefulWidget {
  const GoalFormScreen({required this.onSave, this.initialGoal, super.key});

  final SavingsGoal? initialGoal;
  final Future<void> Function(SavingsGoal goal) onSave;

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetController;
  late final TextEditingController _balanceController;
  late final TextEditingController _categoryController;
  late SavingFrequency _frequency;
  late bool _priority;
  DateTime? _deadline;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    _nameController = TextEditingController(text: goal?.name ?? '');
    _targetController = TextEditingController(
      text: goal == null ? '' : goal.targetAmount.toString(),
    );
    _balanceController = TextEditingController(
      text: goal == null ? '' : goal.currentBalance.toString(),
    );
    _categoryController = TextEditingController(text: goal?.category ?? '');
    _frequency = goal?.frequency ?? SavingFrequency.monthly;
    _priority = (goal?.priority ?? 0) > 0;
    _deadline = goal?.deadline;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _balanceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  int _amount(TextEditingController controller) {
    return int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  }

  Future<void> _pickDeadline() async {
    final now = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _deadline == null || _deadline!.isBefore(now)
          ? now.add(const Duration(days: 30))
          : _deadline!,
      firstDate: now,
      lastDate: DateTime(now.year + 20, 12, 31),
    );
    if (selected != null) setState(() => _deadline = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    final target = _amount(_targetController);
    final balance = _amount(_balanceController);
    if (balance > target) {
      setState(() => _saveError = 'Saldo awal tidak boleh melebihi target.');
      return;
    }

    final now = DateTime.now();
    final old = widget.initialGoal;
    final goal = SavingsGoal(
      id: old?.id ?? createGoalId(),
      name: _nameController.text.trim(),
      targetAmount: target,
      currentBalance: balance,
      frequency: _frequency,
      status: balance >= target
          ? SavingsGoalStatus.completed
          : old?.status == SavingsGoalStatus.archived
          ? SavingsGoalStatus.archived
          : SavingsGoalStatus.active,
      priority: _priority ? 1 : 0,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
      deadline: _deadline,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      archivedAt: old?.archivedAt,
      completedAt: balance >= target ? old?.completedAt ?? now : null,
    );

    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(goal);
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Target belum tersimpan. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialGoal != null;
    return Scaffold(
      key: const Key('goal-form-screen'),
      appBar: AppBar(title: Text(editing ? 'Ubah target' : 'Target baru')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              TextFormField(
                key: const Key('goal-name-field'),
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 60,
                decoration: const InputDecoration(
                  labelText: 'Nama target',
                  hintText: 'Contoh: Dana liburan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nama target wajib diisi.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('goal-target-field'),
                controller: _targetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Nominal target',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
                validator: (_) => _amount(_targetController) <= 0
                    ? 'Nominal target harus lebih dari nol.'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('goal-balance-field'),
                controller: _balanceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Saldo awal',
                  prefixText: 'Rp ',
                  hintText: '0',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<SavingFrequency>(
                key: const Key('goal-frequency-field'),
                initialValue: _frequency,
                decoration: const InputDecoration(
                  labelText: 'Frekuensi menabung',
                  border: OutlineInputBorder(),
                ),
                items: SavingFrequency.values
                    .map(
                      (frequency) => DropdownMenuItem(
                        value: frequency,
                        child: Text(_frequencyLabel(frequency)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _frequency = value);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _categoryController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Kategori (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                leading: const Icon(Icons.event_outlined),
                title: const Text('Tenggat'),
                subtitle: Text(
                  _deadline == null ? 'Tanpa tenggat' : _formatDate(_deadline!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_deadline != null)
                      IconButton(
                        tooltip: 'Hapus tenggat',
                        onPressed: () => setState(() => _deadline = null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    IconButton(
                      key: const Key('goal-deadline-picker'),
                      tooltip: 'Pilih tenggat',
                      onPressed: _pickDeadline,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Jadikan target prioritas'),
                value: _priority,
                activeThumbColor: AppColors.primary,
                onChanged: (value) => setState(() => _priority = value),
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _saveError!,
                  key: const Key('goal-save-error'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              FilledButton(
                key: const Key('goal-save-button'),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(editing ? 'Simpan perubahan' : 'Simpan target'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _frequencyLabel(SavingFrequency frequency) => switch (frequency) {
  SavingFrequency.daily => 'Harian',
  SavingFrequency.weekly => 'Mingguan',
  SavingFrequency.monthly => 'Bulanan',
  SavingFrequency.flexible => 'Fleksibel',
};

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
