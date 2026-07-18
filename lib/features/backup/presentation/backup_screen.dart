import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../../security/presentation/pin_reauthentication_screen.dart';
import '../data/backup_file_gateway.dart';
import '../data/backup_service.dart';
import '../domain/backup_data.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    required this.service,
    required this.fileGateway,
    required this.pinRepository,
    required this.onRestored,
    this.requirePinAuthentication = true,
    this.allowCreate = true,
    this.closeAfterRestore = false,
    super.key,
  });

  final BackupService service;
  final BackupFileGateway fileGateway;
  final PinAuthRepository pinRepository;
  final Future<void> Function() onRestored;
  final bool requirePinAuthentication;
  final bool allowCreate;
  final bool closeAfterRestore;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;
  String? _message;
  bool _messageIsError = false;

  Future<bool> _reauthenticate(String title) async {
    if (!widget.requirePinAuthentication) return true;
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PinReauthenticationScreen(
          pinRepository: widget.pinRepository,
          title: title,
          description: 'Masukkan PIN untuk melanjutkan tindakan sensitif ini.',
        ),
      ),
    );
    return verified == true;
  }

  Future<void> _createBackup() async {
    if (_busy || !await _reauthenticate('Buat backup terenkripsi')) return;
    if (!mounted) return;
    final password = await showDialog<String>(
      context: context,
      builder: (context) => const _BackupPasswordDialog(confirmPassword: true),
    );
    if (password == null || !mounted) return;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await widget.service.create(password);
      if (!mounted) return;
      final date = DateTime.now();
      final fileName =
          'pocketly-${date.year}${_two(date.month)}${_two(date.day)}-'
          '${_two(date.hour)}${_two(date.minute)}.pocketly';
      final box = context.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;
      final shared = await widget.fileGateway.exportBackup(
        bytes: bytes,
        fileName: fileName,
        sharePositionOrigin: origin,
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageIsError = false;
        _message = shared
            ? 'Backup terenkripsi siap disimpan.'
            : 'Ekspor backup dibatalkan.';
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _messageIsError = true;
        _message = 'Backup belum dapat dibuat. Silakan coba lagi.';
      });
    }
  }

  Future<void> _restoreBackup() async {
    if (_busy || !await _reauthenticate('Pulihkan backup')) return;
    if (!mounted) return;
    try {
      final bytes = await widget.fileGateway.pickBackup();
      if (bytes == null || !mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (context) =>
            const _BackupPasswordDialog(confirmPassword: false),
      );
      if (password == null || !mounted) return;
      setState(() {
        _busy = true;
        _message = null;
      });
      final data = await widget.service.inspect(bytes, password);
      if (!mounted) return;
      setState(() => _busy = false);
      final confirmed = await _confirmRestore(data);
      if (confirmed != true || !mounted) return;
      setState(() => _busy = true);
      await widget.service.restore(data);
      await widget.onRestored();
      if (!mounted) return;
      if (widget.closeAfterRestore) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _busy = false;
        _messageIsError = false;
        _message = 'Backup berhasil dipulihkan.';
      });
    } on FormatException catch (error) {
      if (mounted) _showRestoreError(error.message);
    } on BackupException catch (error) {
      if (mounted) _showRestoreError(error.message);
    } on Object {
      if (mounted) {
        _showRestoreError('File backup tidak dapat dibuka atau dipulihkan.');
      }
    }
  }

  void _showRestoreError(String message) {
    setState(() {
      _busy = false;
      _messageIsError = true;
      _message = message;
    });
  }

  Future<bool?> _confirmRestore(BackupData data) => showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Ganti data lokal?'),
      content: Text(
        'Backup berisi ${data.goals.length} target dan '
        '${data.transactions.length} transaksi. Data Pocketly saat ini akan '
        'diganti secara atomik.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('confirm-restore-backup'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Pulihkan'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('backup-screen'),
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: AppBar(
        title: const Text('Backup terenkripsi'),
        backgroundColor: const Color(0xFFF8F7FC),
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.enhanced_encryption_outlined,
                    size: 44,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Backup dilindungi kata sandi terpisah',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Simpan kata sandi backup dengan aman. Pocketly tidak dapat '
                    'memulihkan file jika kata sandinya hilang.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (widget.allowCreate) ...[
              _BackupActionCard(
                icon: Icons.backup_outlined,
                title: 'Buat backup baru',
                description:
                    'Enkripsi seluruh target dan transaksi, lalu pilih tempat penyimpanan melalui share sheet.',
                buttonKey: const Key('create-backup-action'),
                buttonLabel: 'Buat dan simpan backup',
                onPressed: _busy ? null : _createBackup,
              ),
              const SizedBox(height: 16),
            ],
            _BackupActionCard(
              icon: Icons.restore_page_outlined,
              title: 'Pulihkan dari file',
              description:
                  'Pilih file .pocketly. Data baru diterapkan setelah kata sandi dan isi file tervalidasi.',
              buttonKey: const Key('restore-backup-action'),
              buttonLabel: 'Pilih file backup',
              onPressed: _busy ? null : _restoreBackup,
            ),
            if (_busy) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_message != null) ...[
              const SizedBox(height: 18),
              Text(
                _message!,
                key: const Key('backup-message'),
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
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonKey,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final Key buttonKey;
  final String buttonLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.muted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(description),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              key: buttonKey,
              onPressed: onPressed,
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackupPasswordDialog extends StatefulWidget {
  const _BackupPasswordDialog({required this.confirmPassword});

  final bool confirmPassword;

  @override
  State<_BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<_BackupPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    if (widget.confirmPassword && password.length < 10) {
      setState(() => _error = 'Gunakan minimal 10 karakter.');
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = 'Kata sandi wajib diisi.');
      return;
    }
    if (widget.confirmPassword && password != _confirmationController.text) {
      setState(() => _error = 'Konfirmasi kata sandi tidak sama.');
      return;
    }
    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.confirmPassword
            ? 'Buat kata sandi backup'
            : 'Masukkan kata sandi backup',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('backup-password-field'),
              controller: _passwordController,
              obscureText: _obscure,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: 'Kata sandi backup',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            if (widget.confirmPassword) ...[
              const SizedBox(height: 12),
              TextField(
                key: const Key('backup-password-confirmation-field'),
                controller: _confirmationController,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                decoration: const InputDecoration(
                  labelText: 'Ulangi kata sandi',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const Key('backup-password-error'),
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('backup-password-submit'),
          onPressed: _submit,
          child: const Text('Lanjutkan'),
        ),
      ],
    );
  }
}

String _two(int value) => value.toString().padLeft(2, '0');
