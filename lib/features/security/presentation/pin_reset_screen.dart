import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import '../domain/pin_policy.dart';
import 'widgets/pin_input_widgets.dart';

class PinResetScreen extends StatefulWidget {
  const PinResetScreen({required this.pinRepository, super.key});

  final PinAuthRepository pinRepository;

  @override
  State<PinResetScreen> createState() => _PinResetScreenState();
}

class _PinResetScreenState extends State<PinResetScreen> {
  String _input = '';
  String? _firstPin;
  String? _error;
  bool _confirming = false;
  bool _saving = false;

  void _enterDigit(String digit) {
    if (_input.length >= 6 || _saving) return;
    setState(() {
      _input += digit;
      _error = null;
    });
  }

  void _removeDigit() {
    if (_input.isEmpty || _saving) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  Future<void> _continue() async {
    if (!_confirming) {
      final validation = PinPolicy.validate(_input);
      if (validation != null) {
        setState(() {
          _input = '';
          _error = validation;
        });
        return;
      }
      setState(() {
        _firstPin = _input;
        _input = '';
        _confirming = true;
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
    setState(() => _saving = true);
    try {
      await widget.pinRepository.createPin(_input);
    } on Object {
      if (!mounted) return;
      setState(() {
        _input = '';
        _saving = false;
        _error = 'PIN baru belum dapat disimpan dengan aman.';
      });
      return;
    }
    if (mounted) Navigator.pop(context, true);
  }

  void _back() {
    if (!_confirming) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _input = '';
      _firstPin = null;
      _error = null;
      _confirming = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('pin-reset-screen'),
      appBar: AppBar(
        title: const Text('Buat PIN baru'),
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
                    Icons.lock_reset_rounded,
                    size: compact ? 36 : 46,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: compact ? 8 : 16),
                  Text(
                    _confirming ? 'Ulangi PIN baru' : 'Atur PIN baru',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _confirming
                        ? 'Pastikan konfirmasi sama dengan PIN baru.'
                        : 'Data tabunganmu tetap tersimpan di perangkat ini.',
                    textAlign: TextAlign.center,
                  ),
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
                              key: const Key('pin-reset-error'),
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
                        enabled: !_saving,
                        onDigit: _enterDigit,
                        onDelete: _removeDigit,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  FilledButton(
                    key: const Key('pin-reset-continue'),
                    onPressed: _input.length == 6 && !_saving
                        ? _continue
                        : null,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink,
                            ),
                          )
                        : Text(_confirming ? 'Simpan PIN baru' : 'Lanjut'),
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
