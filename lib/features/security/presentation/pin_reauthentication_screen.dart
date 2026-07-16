import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/pin_auth_repository.dart';
import 'widgets/pin_input_widgets.dart';

class PinReauthenticationScreen extends StatefulWidget {
  const PinReauthenticationScreen({
    required this.pinRepository,
    required this.title,
    required this.description,
    super.key,
  });

  final PinAuthRepository pinRepository;
  final String title;
  final String description;

  @override
  State<PinReauthenticationScreen> createState() =>
      _PinReauthenticationScreenState();
}

class _PinReauthenticationScreenState extends State<PinReauthenticationScreen> {
  String _input = '';
  String? _error;
  bool _verifying = false;

  void _enterDigit(String digit) {
    if (_input.length >= 6 || _verifying) return;
    setState(() {
      _input += digit;
      _error = null;
    });
  }

  void _removeDigit() {
    if (_input.isEmpty || _verifying) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final result = await widget.pinRepository.verifyPin(_input);
    if (!mounted) return;
    if (result.status == PinVerificationStatus.success) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _input = '';
      _verifying = false;
      _error = switch (result.status) {
        PinVerificationStatus.incorrect => 'PIN salah. Coba lagi.',
        PinVerificationStatus.locked => 'PIN sedang dikunci sementara.',
        _ => 'PIN tidak dapat diverifikasi dengan aman.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('pin-reauthentication-screen'),
      appBar: AppBar(title: const Text('Verifikasi keamanan')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 620;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: compact ? 34 : 44,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: compact ? 8 : 16),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.description, textAlign: TextAlign.center),
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
                              key: const Key('pin-reauthentication-error'),
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
                        enabled: !_verifying,
                        onDigit: _enterDigit,
                        onDelete: _removeDigit,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  FilledButton(
                    key: const Key('pin-reauthenticate'),
                    onPressed: _input.length == 6 && !_verifying
                        ? _verify
                        : null,
                    child: _verifying
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ink,
                            ),
                          )
                        : const Text('Verifikasi PIN'),
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
