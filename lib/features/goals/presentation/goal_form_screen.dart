import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/formatters/rupiah_input_formatter.dart';
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
      text: goal == null ? '' : formatRupiahDigits(goal.targetAmount),
    );
    _balanceController = TextEditingController(
      text: goal == null ? '' : formatRupiahDigits(goal.currentBalance),
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
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          _GoalSaveProgressDialog(operation: () => widget.onSave(goal)),
    );
    if (!mounted) return;
    if (saved == true) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = false;
      _saveError = 'Target belum tersimpan. Silakan coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialGoal != null;
    return Scaffold(
      key: const Key('goal-form-screen'),
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
        title: Text(editing ? 'Ubah target' : 'Target baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.76),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    _HeaderIcon(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wujudkan rencanamu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Mulai dari target yang jelas dan langkah kecil yang konsisten.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _FormSection(
                icon: Icons.flag_rounded,
                title: 'Tentang target',
                subtitle: 'Beri nama yang membuatmu tetap termotivasi.',
                children: [
                  TextFormField(
                    key: const Key('goal-name-field'),
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 60,
                    decoration: _fieldDecoration(
                      label: 'Nama target',
                      hint: 'Contoh: Dana liburan',
                      icon: Icons.edit_outlined,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama target wajib diisi.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _categoryController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _fieldDecoration(
                      label: 'Kategori (opsional)',
                      hint: 'Liburan, pendidikan, kendaraan…',
                      icon: Icons.category_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _FormSection(
                icon: Icons.savings_rounded,
                title: 'Rencana tabungan',
                subtitle: 'Atur nominal dan ritme menabung yang nyaman.',
                children: [
                  TextFormField(
                    key: const Key('goal-target-field'),
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupiahInputFormatter()],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: _fieldDecoration(
                      label: 'Nominal target',
                      hint: '10.000.000',
                      icon: Icons.payments_outlined,
                    ).copyWith(prefixText: 'Rp '),
                    validator: (_) => _amount(_targetController) <= 0
                        ? 'Nominal target harus lebih dari nol.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('goal-balance-field'),
                    controller: _balanceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: const [RupiahInputFormatter()],
                    decoration: _fieldDecoration(
                      label: 'Saldo awal',
                      hint: '0',
                      icon: Icons.account_balance_wallet_outlined,
                    ).copyWith(prefixText: 'Rp '),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SavingFrequency>(
                    key: const Key('goal-frequency-field'),
                    initialValue: _frequency,
                    decoration: _fieldDecoration(
                      label: 'Frekuensi menabung',
                      icon: Icons.repeat_rounded,
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
                  const SizedBox(height: 12),
                  Material(
                    color: const Color(0xFFF8F7FC),
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      leading: const Icon(
                        Icons.event_outlined,
                        color: AppColors.primary,
                      ),
                      title: const Text(
                        'Tenggat',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        _deadline == null
                            ? 'Tanpa tenggat'
                            : _formatDate(_deadline!),
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
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    secondary: const Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      'Target prioritas',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Tampilkan target ini lebih utama.'),
                    value: _priority,
                    activeThumbColor: AppColors.primary,
                    onChanged: (value) => setState(() => _priority = value),
                  ),
                ],
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _saveError!,
                    key: const Key('goal-save-error'),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('goal-save-button'),
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(62),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.auto_awesome_rounded),
                    const SizedBox(width: 10),
                    Text(editing ? 'Simpan perubahan' : 'Simpan target'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  String? hint,
}) {
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(18)),
    borderSide: BorderSide(color: Color(0xFFE9E6F1)),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icon, color: AppColors.primary),
    filled: true,
    fillColor: const Color(0xFFF8F7FC),
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: AppColors.primary, width: 1.7),
    ),
    errorBorder: border.copyWith(
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.7),
    ),
  );
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: const Icon(Icons.savings_rounded, color: Colors.white, size: 32),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEEEAF5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.54),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

class _GoalSaveProgressDialog extends StatefulWidget {
  const _GoalSaveProgressDialog({required this.operation});

  final Future<void> Function() operation;

  @override
  State<_GoalSaveProgressDialog> createState() =>
      _GoalSaveProgressDialogState();
}

class _GoalSaveProgressDialogState extends State<_GoalSaveProgressDialog> {
  bool _success = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      await Future.wait([
        widget.operation(),
        Future<void>.delayed(const Duration(milliseconds: 650)),
      ]);
      if (!mounted) return;
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _failed,
      child: Dialog(
        key: const Key('goal-save-progress-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, animation) => ScaleTransition(
                  scale: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _failed
                    ? Container(
                        key: const ValueKey('failed'),
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.redAccent,
                          size: 48,
                        ),
                      )
                    : _success
                    ? Container(
                        key: const Key('goal-save-success-check'),
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      )
                    : SizedBox(
                        key: const ValueKey('loading'),
                        width: 86,
                        height: 86,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const SizedBox(
                              width: 78,
                              height: 78,
                              child: CircularProgressIndicator(
                                strokeWidth: 5,
                                color: AppColors.primary,
                                backgroundColor: Color(0xFFEDE7FA),
                              ),
                            ),
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.12,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.savings_rounded,
                                color: AppColors.primary,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _failed
                      ? 'Belum berhasil disimpan'
                      : _success
                      ? 'Target berhasil disimpan!'
                      : 'Menyimpan target…',
                  key: ValueKey('title-$_failed-$_success'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _failed
                    ? 'Periksa kembali dan coba simpan sekali lagi.'
                    : _success
                    ? 'Satu langkah lebih dekat dengan tujuanmu.'
                    : 'Pocketly sedang mengamankan perubahanmu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.58),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: _success || _failed ? 1 : null,
                  color: _failed ? Colors.redAccent : AppColors.primary,
                  backgroundColor: const Color(0xFFEDE7FA),
                ),
              ),
              if (_failed) ...[
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Kembali ke formulir'),
                ),
              ],
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
