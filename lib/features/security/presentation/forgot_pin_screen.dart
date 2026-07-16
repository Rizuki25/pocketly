import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/biometric_authenticator.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../../backup/data/backup_file_gateway.dart';
import '../../backup/data/backup_service.dart';
import '../../backup/presentation/backup_screen.dart';
import 'pin_reset_screen.dart';

class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({
    required this.pinRepository,
    required this.biometricAuthenticator,
    required this.biometricEnabled,
    required this.onPinReset,
    required this.onResetLocalData,
    required this.onBack,
    this.backupServiceProvider,
    this.backupFileGateway,
    super.key,
  });

  final PinAuthRepository pinRepository;
  final BiometricAuthenticator biometricAuthenticator;
  final bool biometricEnabled;
  final Future<void> Function() onPinReset;
  final Future<void> Function() onResetLocalData;
  final VoidCallback onBack;
  final Future<BackupService> Function()? backupServiceProvider;
  final BackupFileGateway? backupFileGateway;

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  bool _checking = true;
  bool _biometricAvailable = false;
  bool _authenticating = false;
  bool _resettingData = false;
  bool _restoringBackup = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    if (!widget.biometricEnabled) {
      setState(() => _checking = false);
      return;
    }
    final availability = await widget.biometricAuthenticator
        .checkAvailability();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _biometricAvailable = availability == BiometricAvailability.available;
      if (!_biometricAvailable) {
        _message = availability == BiometricAvailability.notEnrolled
            ? 'Biometrik tidak lagi terdaftar pada perangkat.'
            : 'Biometrik tidak tersedia untuk pemulihan.';
      }
    });
  }

  Future<void> _recoverWithBiometric() async {
    if (!_biometricAvailable || _authenticating) return;
    setState(() {
      _authenticating = true;
      _message = null;
    });
    final status = await widget.biometricAuthenticator.authenticate();
    if (!mounted) return;
    if (status != BiometricAuthStatus.success) {
      setState(() {
        _authenticating = false;
        _message = _biometricError(status);
        if (status == BiometricAuthStatus.temporaryLockout ||
            status == BiometricAuthStatus.permanentLockout ||
            status == BiometricAuthStatus.unavailable) {
          _biometricAvailable = false;
        }
      });
      return;
    }
    setState(() => _authenticating = false);
    final reset = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            PinResetScreen(pinRepository: widget.pinRepository),
      ),
    );
    if (reset == true) await widget.onPinReset();
  }

  Future<void> _startLocalReset() async {
    final understood = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset seluruh data lokal?'),
        content: const Text(
          'Semua target, transaksi, PIN, dan pengaturan Pocketly akan dihapus '
          'permanen dari perangkat ini. Pastikan backup terenkripsi sudah '
          'disimpan jika data masih diperlukan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('local-reset-first-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Saya mengerti'),
          ),
        ],
      ),
    );
    if (understood != true || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _TypedResetConfirmationDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _resettingData = true;
      _message = null;
    });
    try {
      await widget.onResetLocalData();
      if (mounted) setState(() => _resettingData = false);
    } on Object {
      if (!mounted) return;
      setState(() {
        _resettingData = false;
        _message = 'Data lokal belum dapat direset dengan aman. Coba lagi.';
      });
    }
  }

  Future<void> _recoverWithBackup() async {
    final provider = widget.backupServiceProvider;
    final gateway = widget.backupFileGateway;
    if (provider == null || gateway == null || _restoringBackup) return;
    setState(() {
      _restoringBackup = true;
      _message = null;
    });
    try {
      final service = await provider();
      if (!mounted) return;
      setState(() => _restoringBackup = false);
      final restored = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => BackupScreen(
            service: service,
            fileGateway: gateway,
            pinRepository: widget.pinRepository,
            onRestored: () async {},
            requirePinAuthentication: false,
            allowCreate: false,
            closeAfterRestore: true,
          ),
        ),
      );
      if (restored != true || !mounted) return;
      final pinReset = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) =>
              PinResetScreen(pinRepository: widget.pinRepository),
        ),
      );
      if (pinReset == true) await widget.onPinReset();
    } on Object {
      if (!mounted) return;
      setState(() {
        _restoringBackup = false;
        _message = 'Pemulihan backup belum dapat dimulai.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('forgot-pin-screen'),
      appBar: AppBar(
        title: const Text('Lupa PIN'),
        leading: BackButton(onPressed: widget.onBack),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.key_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pulihkan akses lokal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text(
              'Pocketly tidak memiliki akun atau server untuk mengirim ulang PIN. '
              'Pilih metode yang masih tersedia di perangkat ini.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _RecoveryCard(
              icon: Icons.fingerprint_rounded,
              title: 'Pulihkan dengan biometrik',
              description: _checking
                  ? 'Memeriksa biometrik perangkat...'
                  : _biometricAvailable
                  ? 'Verifikasi sidik jari atau wajah untuk membuat PIN baru tanpa menghapus data.'
                  : 'Metode ini tidak tersedia. Data tidak dapat dipulihkan hanya dengan menebak kepemilikan perangkat.',
              action: _checking
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                      key: const Key('recover-with-biometric'),
                      onPressed: _biometricAvailable && !_authenticating
                          ? _recoverWithBiometric
                          : null,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: Text(
                        _authenticating
                            ? 'Memverifikasi...'
                            : 'Verifikasi biometrik',
                      ),
                    ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                key: const Key('forgot-pin-message'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 16),
            _RecoveryCard(
              icon: Icons.restore_page_outlined,
              title: 'Pulihkan file backup',
              description:
                  'Gunakan file .pocketly dan kata sandi backup untuk mengganti data lokal, lalu buat PIN baru.',
              action: OutlinedButton.icon(
                key: const Key('recover-with-backup'),
                onPressed:
                    widget.backupServiceProvider != null &&
                        widget.backupFileGateway != null &&
                        !_restoringBackup
                    ? _recoverWithBackup
                    : null,
                icon: _restoringBackup
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.folder_open_outlined),
                label: Text(
                  _restoringBackup ? 'Membuka backup...' : 'Pilih file backup',
                ),
              ),
            ),
            const SizedBox(height: 16),
            _RecoveryCard(
              icon: Icons.delete_forever_outlined,
              title: 'Mulai ulang Pocketly',
              description:
                  'Gunakan hanya jika biometrik tidak dapat dipakai dan kamu menerima kehilangan seluruh data lokal.',
              danger: true,
              action: OutlinedButton.icon(
                key: const Key('reset-local-data'),
                onPressed: _resettingData ? null : _startLocalReset,
                icon: _resettingData
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_forever_outlined),
                label: Text(
                  _resettingData
                      ? 'Mereset data...'
                      : 'Reset seluruh data lokal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecoveryCard extends StatelessWidget {
  const _RecoveryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.action,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget action;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: danger
              ? Colors.redAccent.withValues(alpha: 0.28)
              : AppColors.muted,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: danger ? Colors.redAccent : AppColors.primary),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 7),
          Text(description),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: action),
        ],
      ),
    );
  }
}

class _TypedResetConfirmationDialog extends StatefulWidget {
  const _TypedResetConfirmationDialog();

  @override
  State<_TypedResetConfirmationDialog> createState() =>
      _TypedResetConfirmationDialogState();
}

class _TypedResetConfirmationDialogState
    extends State<_TypedResetConfirmationDialog> {
  String _value = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi terakhir'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ketik HAPUS untuk menghapus seluruh data Pocketly.'),
          const SizedBox(height: 14),
          TextField(
            key: const Key('local-reset-confirmation-field'),
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => setState(() => _value = value),
            decoration: const InputDecoration(hintText: 'HAPUS'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('local-reset-final-confirm'),
          onPressed: _value.trim() == 'HAPUS'
              ? () => Navigator.pop(context, true)
              : null,
          child: const Text('Hapus permanen'),
        ),
      ],
    );
  }
}

String _biometricError(BiometricAuthStatus status) => switch (status) {
  BiometricAuthStatus.notRecognized => 'Biometrik belum dikenali. Coba lagi.',
  BiometricAuthStatus.cancelled => 'Verifikasi biometrik dibatalkan.',
  BiometricAuthStatus.temporaryLockout ||
  BiometricAuthStatus.permanentLockout =>
    'Biometrik sedang terkunci oleh sistem perangkat.',
  BiometricAuthStatus.unavailable || BiometricAuthStatus.error =>
    'Biometrik tidak dapat digunakan untuk pemulihan.',
  BiometricAuthStatus.success => '',
};
