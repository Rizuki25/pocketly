import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../domain/pin_policy.dart';
import 'widgets/pin_input_widgets.dart';

enum _ChangePinStep { current, create, confirm }

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({
    required this.pinRepository,
    required this.onChanged,
    super.key,
  });

  final PinAuthRepository pinRepository;
  final Future<void> Function() onChanged;

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  _ChangePinStep _step = _ChangePinStep.current;
  String _input = '';
  String? _newPin;
  String? _error;
  bool _processing = false;

  void _enterDigit(String digit) {
    if (_input.length >= 6 || _processing) return;
    setState(() {
      _input += digit;
      _error = null;
    });
  }

  void _removeDigit() {
    if (_input.isEmpty || _processing) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  Future<void> _continue() async {
    if (_processing || _input.length != 6) return;
    switch (_step) {
      case _ChangePinStep.current:
        await _verifyCurrentPin();
        return;
      case _ChangePinStep.create:
        final validation = PinPolicy.validate(_input);
        if (validation != null) {
          setState(() {
            _input = '';
            _error = validation;
          });
          return;
        }
        setState(() {
          _newPin = _input;
          _input = '';
          _error = null;
          _step = _ChangePinStep.confirm;
        });
        return;
      case _ChangePinStep.confirm:
        if (_input != _newPin) {
          setState(() {
            _input = '';
            _error = 'PIN tidak sama. Masukkan ulang konfirmasi PIN.';
          });
          return;
        }
        await _saveNewPin();
    }
  }

  Future<void> _verifyCurrentPin() async {
    setState(() => _processing = true);
    final result = await widget.pinRepository.verifyPin(_input);
    if (!mounted) return;
    if (result.status == PinVerificationStatus.success) {
      setState(() {
        _input = '';
        _error = null;
        _processing = false;
        _step = _ChangePinStep.create;
      });
      return;
    }
    setState(() {
      _input = '';
      _processing = false;
      _error = _verificationMessage(result);
    });
  }

  Future<void> _saveNewPin() async {
    setState(() => _processing = true);
    try {
      await widget.pinRepository.createPin(_input);
    } on Object {
      if (!mounted) return;
      setState(() {
        _input = '';
        _processing = false;
        _error = 'PIN baru belum dapat disimpan dengan aman. Coba lagi.';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _input = '';
      _processing = false;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.verified_user_rounded,
          size: 44,
          color: AppColors.primary,
        ),
        title: const Text('PIN berhasil diubah'),
        content: const Text(
          'Pocketly akan dikunci kembali. Gunakan PIN baru saat masuk.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            key: const Key('pin-change-success-continue'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kunci Pocketly'),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.onChanged();
  }

  void _back() {
    if (_step == _ChangePinStep.current) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step = _step == _ChangePinStep.confirm
          ? _ChangePinStep.create
          : _ChangePinStep.current;
      _input = '';
      _newPin = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final (title, description, button) = switch (_step) {
      _ChangePinStep.current => (
        'Masukkan PIN saat ini',
        'Verifikasi identitasmu sebelum mengganti PIN.',
        'Verifikasi PIN',
      ),
      _ChangePinStep.create => (
        'Buat PIN baru',
        'Gunakan 6 digit yang kuat dan mudah kamu ingat.',
        'Lanjut',
      ),
      _ChangePinStep.confirm => (
        'Ulangi PIN baru',
        'Pastikan konfirmasi sama dengan PIN baru.',
        'Ubah PIN',
      ),
    };
    return Scaffold(
      key: const Key('change-pin-screen'),
      appBar: AppBar(
        title: const Text('Ubah PIN'),
        leading: BackButton(onPressed: _back),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 620;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                children: [
                  Icon(
                    Icons.password_rounded,
                    size: compact ? 34 : 44,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: compact ? 8 : 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(description, textAlign: TextAlign.center),
                  SizedBox(height: compact ? 14 : 24),
                  PocketlyPinDots(
                    length: _input.length,
                    hasError: _error != null,
                  ),
                  SizedBox(
                    height: compact ? 42 : 56,
                    child: _error == null
                        ? null
                        : Center(
                            child: Text(
                              _error!,
                              key: const Key('change-pin-error'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                        enabled: !_processing,
                        onDigit: _enterDigit,
                        onDelete: _removeDigit,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  FilledButton(
                    key: const Key('change-pin-continue'),
                    onPressed: _input.length == 6 && !_processing
                        ? _continue
                        : null,
                    child: _processing
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink,
                            ),
                          )
                        : Text(button),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _verificationMessage(
  PinVerificationResult result,
) => switch (result.status) {
  PinVerificationStatus.incorrect => 'PIN saat ini salah.',
  PinVerificationStatus.locked =>
    'Terlalu banyak percobaan. Coba lagi dalam ${_duration(result.retryAfter)}.',
  PinVerificationStatus.notConfigured => 'PIN belum dikonfigurasi.',
  PinVerificationStatus.credentialCorrupted =>
    'Data PIN tidak dapat diverifikasi dengan aman.',
  PinVerificationStatus.success => '',
};

String _duration(Duration duration) {
  if (duration.inMinutes >= 1) {
    return '${duration.inMinutes + (duration.inSeconds % 60 == 0 ? 0 : 1)} menit';
  }
  return '${duration.inSeconds.clamp(1, 59)} detik';
}
