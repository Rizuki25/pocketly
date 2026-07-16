import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../domain/pin_policy.dart';
import 'widgets/pin_input_widgets.dart';

enum _PinStep { create, confirm, success }

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({
    required this.onBack,
    required this.onCompleted,
    required this.pinRepository,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onCompleted;
  final PinAuthRepository pinRepository;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  _PinStep _step = _PinStep.create;
  String _input = '';
  String? _firstPin;
  String? _error;
  bool _isSaving = false;

  void _enterDigit(String digit) {
    if (_input.length >= 6 || _step == _PinStep.success) return;
    setState(() {
      _input += digit;
      _error = null;
    });
  }

  void _removeDigit() {
    if (_input.isEmpty || _step == _PinStep.success) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  Future<void> _continue() async {
    if (_step == _PinStep.create) {
      final validationError = PinPolicy.validate(_input);
      if (validationError != null) {
        setState(() {
          _error = validationError;
          _input = '';
        });
        return;
      }
      setState(() {
        _firstPin = _input;
        _input = '';
        _error = null;
        _step = _PinStep.confirm;
      });
      return;
    }

    if (_input != _firstPin) {
      setState(() {
        _input = '';
        _error = 'PIN tidak sama. Masukkan ulang konfirmasi PIN.';
      });
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.pinRepository.createPin(_input);
    } on Object {
      if (!mounted) return;
      setState(() {
        _input = '';
        _error = 'PIN belum dapat disimpan dengan aman. Coba lagi.';
        _isSaving = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _input = '';
      _firstPin = null;
      _error = null;
      _isSaving = false;
      _step = _PinStep.success;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showPinSuccessDialog();
    });
  }

  Future<void> _showPinSuccessDialog() async {
    final continueToBiometric = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'PIN berhasil dibuat',
      barrierColor: AppColors.ink.withValues(alpha: 0.62),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _PinSuccessDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.82, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    if (mounted && continueToBiometric == true) widget.onCompleted();
  }

  void _goBack() {
    if (_step == _PinStep.confirm) {
      setState(() {
        _step = _PinStep.create;
        _input = '';
        _firstPin = null;
        _error = null;
      });
      return;
    }
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('pin-setup-screen'),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _step == _PinStep.success
              ? const _PinReadyView(key: ValueKey('pin-ready'))
              : _PinEntryView(
                  key: ValueKey(_step),
                  step: _step,
                  inputLength: _input.length,
                  error: _error,
                  isSaving: _isSaving,
                  onBack: _goBack,
                  onDigit: _enterDigit,
                  onDelete: _removeDigit,
                  onContinue: _input.length == 6 && !_isSaving
                      ? _continue
                      : null,
                ),
        ),
      ),
    );
  }
}

class _PinEntryView extends StatelessWidget {
  const _PinEntryView({
    required this.step,
    required this.inputLength,
    required this.error,
    required this.isSaving,
    required this.onBack,
    required this.onDigit,
    required this.onDelete,
    required this.onContinue,
    super.key,
  });

  final _PinStep step;
  final int inputLength;
  final String? error;
  final bool isSaving;
  final VoidCallback onBack;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final confirming = step == _PinStep.confirm;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 24, 0),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                tooltip: 'Kembali',
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const Spacer(),
              Text(
                confirming ? 'LANGKAH 2 DARI 2' : 'LANGKAH 1 DARI 2',
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: 0.48),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 600;
              return Padding(
                padding: EdgeInsets.fromLTRB(24, compact ? 4 : 18, 24, 18),
                child: Column(
                  children: [
                    Icon(
                      confirming
                          ? Icons.verified_user_outlined
                          : Icons.password_rounded,
                      size: compact ? 34 : 42,
                      color: AppColors.primary,
                    ),
                    SizedBox(height: compact ? 10 : 18),
                    Text(
                      confirming ? 'Ulangi PIN-mu' : 'Buat PIN 6 digit',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(fontSize: compact ? 27 : 31),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      confirming
                          ? 'Pastikan PIN sama dengan yang kamu buat sebelumnya.'
                          : 'PIN digunakan untuk membuka Pocketly dan melindungi data lokalmu.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink.withValues(alpha: 0.6),
                        fontSize: compact ? 13 : 14,
                      ),
                    ),
                    SizedBox(height: compact ? 14 : 24),
                    PocketlyPinDots(
                      length: inputLength,
                      hasError: error != null,
                    ),
                    SizedBox(
                      height: compact ? 34 : 46,
                      child: error == null
                          ? null
                          : Center(
                              child: Text(
                                error!,
                                key: const Key('pin-error'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.ink,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: PocketlyPinKeypad(
                          compact: compact,
                          enabled: !isSaving,
                          onDigit: onDigit,
                          onDelete: onDelete,
                        ),
                      ),
                    ),
                    SizedBox(height: compact ? 10 : 16),
                    FilledButton(
                      key: const Key('pin-continue'),
                      onPressed: onContinue,
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.ink,
                              ),
                            )
                          : Text(confirming ? 'Konfirmasi PIN' : 'Lanjut'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PinReadyView extends StatelessWidget {
  const _PinReadyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Image.asset(
                'assets/branding/pocketly_logo.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 9),
              const Text(
                'pocketly',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AppColors.primary,
              size: 40,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Keamanan dasar aktif',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'PIN sudah siap melindungi data lokal Pocketly.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.ink.withValues(alpha: 0.58),
              fontSize: 14,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PinSuccessDialog extends StatelessWidget {
  const _PinSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Material(
            color: AppColors.background,
            elevation: 0,
            borderRadius: BorderRadius.circular(32),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: Stack(
                children: [
                  const Positioned(
                    top: -25,
                    right: -18,
                    child: _CelebrationRing(size: 94),
                  ),
                  Positioned(
                    top: 36,
                    left: 30,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 82,
                    right: 38,
                    child: Transform.rotate(
                      angle: 0.7,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(28, 38, 28, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.11,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 82,
                              height: 82,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: AppColors.ink,
                                size: 46,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'PIN berhasil dibuat!',
                          key: const Key('pin-success-title'),
                          textAlign: TextAlign.center,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineLarge?.copyWith(fontSize: 27),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Data lokalmu kini terlindungi. Gunakan PIN ini setiap kali '
                          'Pocketly meminta verifikasi.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.ink.withValues(alpha: 0.62),
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 26),
                        FilledButton(
                          key: const Key('pin-success-continue'),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Lanjutkan'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Berikutnya: aktifkan biometrik',
                          style: TextStyle(
                            color: AppColors.ink.withValues(alpha: 0.46),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CelebrationRing extends StatelessWidget {
  const _CelebrationRing({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.22),
          width: 18,
        ),
      ),
    );
  }
}
