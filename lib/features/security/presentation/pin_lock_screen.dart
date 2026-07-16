import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/biometric_authenticator.dart';
import '../../../core/security/pin_auth_repository.dart';
import 'widgets/pin_input_widgets.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({
    required this.pinRepository,
    required this.biometricAuthenticator,
    required this.biometricEnabled,
    required this.onUnlocked,
    super.key,
  });

  final PinAuthRepository pinRepository;
  final BiometricAuthenticator biometricAuthenticator;
  final bool biometricEnabled;
  final VoidCallback onUnlocked;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _input = '';
  String? _message;
  bool _isVerifying = false;
  bool _isBiometricAuthenticating = false;
  bool _biometricAvailable = false;
  Duration _retryAfter = Duration.zero;
  Timer? _countdownTimer;

  bool get _isLocked => _retryAfter > Duration.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareBiometric());
  }

  Future<void> _prepareBiometric() async {
    if (!widget.biometricEnabled) return;
    final availability = await widget.biometricAuthenticator
        .checkAvailability();
    if (!mounted) return;
    if (availability == BiometricAvailability.available) {
      setState(() => _biometricAvailable = true);
      await _authenticateBiometric();
      return;
    }
    setState(() {
      _biometricAvailable = false;
      _message = availability == BiometricAvailability.notEnrolled
          ? 'Biometrik tidak lagi terdaftar. Gunakan PIN.'
          : 'Biometrik tidak tersedia. Gunakan PIN.';
    });
  }

  Future<void> _authenticateBiometric() async {
    if (!_biometricAvailable || _isBiometricAuthenticating) return;
    setState(() {
      _isBiometricAuthenticating = true;
      _message = null;
    });
    final status = await widget.biometricAuthenticator.authenticate();
    if (!mounted) return;

    switch (status) {
      case BiometricAuthStatus.success:
        setState(() => _isBiometricAuthenticating = false);
        widget.onUnlocked();
      case BiometricAuthStatus.notRecognized:
        setState(() {
          _isBiometricAuthenticating = false;
          _message = 'Biometrik belum dikenali. Coba lagi atau gunakan PIN.';
        });
      case BiometricAuthStatus.cancelled:
        setState(() {
          _isBiometricAuthenticating = false;
          _message = 'Autentikasi dibatalkan. Gunakan PIN atau coba lagi.';
        });
      case BiometricAuthStatus.temporaryLockout:
      case BiometricAuthStatus.permanentLockout:
        setState(() {
          _isBiometricAuthenticating = false;
          _biometricAvailable = false;
          _message = 'Biometrik sedang terkunci. Gunakan PIN.';
        });
      case BiometricAuthStatus.unavailable:
      case BiometricAuthStatus.error:
        setState(() {
          _isBiometricAuthenticating = false;
          _biometricAvailable = false;
          _message = 'Biometrik tidak tersedia. Gunakan PIN.';
        });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _enterDigit(String digit) {
    if (_input.length >= 6 ||
        _isLocked ||
        _isVerifying ||
        _isBiometricAuthenticating) {
      return;
    }
    setState(() {
      _input += digit;
      _message = null;
    });
  }

  void _removeDigit() {
    if (_input.isEmpty ||
        _isLocked ||
        _isVerifying ||
        _isBiometricAuthenticating) {
      return;
    }
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _message = null;
    });
  }

  Future<void> _verify() async {
    if (_input.length != 6 || _isLocked || _isVerifying) return;
    final candidate = _input;
    setState(() {
      _input = '';
      _isVerifying = true;
      _message = null;
    });

    late final PinVerificationResult result;
    try {
      result = await widget.pinRepository.verifyPin(candidate);
    } on Object {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _message = 'Data keamanan tidak dapat dibuka dengan aman.';
      });
      return;
    }
    if (!mounted) return;

    switch (result.status) {
      case PinVerificationStatus.success:
        setState(() => _isVerifying = false);
        widget.onUnlocked();
      case PinVerificationStatus.incorrect:
        setState(() {
          _isVerifying = false;
          _message = 'PIN belum tepat. Silakan coba lagi.';
        });
      case PinVerificationStatus.locked:
        setState(() {
          _isVerifying = false;
          _retryAfter = result.retryAfter;
          _message = null;
        });
        _startCountdown();
      case PinVerificationStatus.notConfigured:
      case PinVerificationStatus.credentialCorrupted:
        setState(() {
          _isVerifying = false;
          _message = 'Kredensial PIN tidak dapat diverifikasi dengan aman.';
        });
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_retryAfter <= const Duration(seconds: 1)) {
        timer.cancel();
        setState(() {
          _retryAfter = Duration.zero;
          _message = 'Kamu dapat mencoba PIN kembali.';
        });
        return;
      }
      setState(() => _retryAfter -= const Duration(seconds: 1));
    });
  }

  String get _lockMessage {
    final totalSeconds = _retryAfter.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (minutes == 0) return 'Coba lagi dalam $seconds detik';
    return 'Coba lagi dalam $minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('pin-lock-screen'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 650;
            return Padding(
              padding: EdgeInsets.fromLTRB(24, compact ? 12 : 28, 24, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/branding/pocketly_logo.png',
                        width: 34,
                        height: 34,
                      ),
                      const SizedBox(width: 9),
                      const Text(
                        'pocketly',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: compact ? 56 : 68,
                    height: compact ? 56 : 68,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 30,
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 18),
                  Text(
                    'Selamat datang kembali',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontSize: compact ? 27 : 31,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan PIN untuk membuka Pocketly.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.ink.withValues(alpha: 0.58),
                      fontSize: 14,
                    ),
                  ),
                  if (_biometricAvailable)
                    TextButton.icon(
                      key: const Key('biometric-retry'),
                      onPressed: _isBiometricAuthenticating
                          ? null
                          : _authenticateBiometric,
                      icon: const Icon(Icons.fingerprint_rounded),
                      label: const Text('Gunakan biometrik'),
                    )
                  else
                    SizedBox(height: compact ? 8 : 12),
                  SizedBox(height: compact ? 14 : 24),
                  PocketlyPinDots(
                    length: _input.length,
                    hasError: _message != null,
                  ),
                  SizedBox(
                    height: compact ? 38 : 50,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: Text(
                          _isLocked ? _lockMessage : _message ?? '',
                          key: ValueKey('${_retryAfter.inSeconds}-$_message'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  PocketlyPinKeypad(
                    compact: compact,
                    enabled:
                        !_isLocked &&
                        !_isVerifying &&
                        !_isBiometricAuthenticating,
                    onDigit: _enterDigit,
                    onDelete: _removeDigit,
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  FilledButton(
                    key: const Key('pin-unlock'),
                    onPressed:
                        _input.length == 6 &&
                            !_isLocked &&
                            !_isVerifying &&
                            !_isBiometricAuthenticating
                        ? _verify
                        : null,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.ink,
                            ),
                          )
                        : const Text('Buka Pocketly'),
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
