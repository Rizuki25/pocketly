import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/security/biometric_authenticator.dart';
import '../../../core/security/biometric_preference_repository.dart';

class BiometricOfferScreen extends StatefulWidget {
  const BiometricOfferScreen({
    required this.authenticator,
    required this.preferenceRepository,
    required this.onFinished,
    super.key,
  });

  final BiometricAuthenticator authenticator;
  final BiometricPreferenceRepository preferenceRepository;
  final VoidCallback onFinished;

  @override
  State<BiometricOfferScreen> createState() => _BiometricOfferScreenState();
}

class _BiometricOfferScreenState extends State<BiometricOfferScreen> {
  BiometricAvailability? _availability;
  String? _message;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    final availability = await widget.authenticator.checkAvailability();
    if (mounted) setState(() => _availability = availability);
  }

  Future<void> _activate() async {
    if (_isAuthenticating || _availability != BiometricAvailability.available) {
      return;
    }
    setState(() {
      _isAuthenticating = true;
      _message = null;
    });
    final status = await widget.authenticator.authenticate();
    if (!mounted) return;

    switch (status) {
      case BiometricAuthStatus.success:
        await widget.preferenceRepository.setEnabled(true);
        if (mounted) widget.onFinished();
      case BiometricAuthStatus.notRecognized:
        setState(() {
          _isAuthenticating = false;
          _message = 'Biometrik belum dikenali. Coba lagi atau pilih nanti.';
        });
      case BiometricAuthStatus.cancelled:
        setState(() {
          _isAuthenticating = false;
          _message = 'Aktivasi dibatalkan. Kamu dapat mencobanya kembali.';
        });
      case BiometricAuthStatus.temporaryLockout:
      case BiometricAuthStatus.permanentLockout:
        setState(() {
          _isAuthenticating = false;
          _message =
              'Biometrik sedang tidak tersedia. PIN tetap dapat digunakan.';
        });
      case BiometricAuthStatus.unavailable:
      case BiometricAuthStatus.error:
        setState(() {
          _isAuthenticating = false;
          _availability = BiometricAvailability.unavailable;
          _message = 'Biometrik tidak dapat digunakan pada perangkat ini.';
        });
    }
  }

  Future<void> _skip() async {
    await widget.preferenceRepository.setEnabled(false);
    if (mounted) widget.onFinished();
  }

  String get _availabilityMessage {
    return switch (_availability) {
      null => 'Memeriksa keamanan perangkat…',
      BiometricAvailability.available =>
        'Gunakan sidik jari atau wajah untuk membuka Pocketly lebih cepat.',
      BiometricAvailability.noHardware =>
        'Perangkat ini tidak memiliki sensor biometrik yang didukung.',
      BiometricAvailability.notEnrolled =>
        'Belum ada sidik jari atau wajah yang terdaftar di perangkat.',
      BiometricAvailability.unavailable =>
        'Biometrik belum dapat digunakan. Kamu tetap dapat masuk dengan PIN.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final available = _availability == BiometricAvailability.available;
    return Scaffold(
      key: const Key('biometric-offer-screen'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('biometric-skip-top'),
                  onPressed: _isAuthenticating ? null : _skip,
                  child: const Text('Nanti saja'),
                ),
              ),
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.muted, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Icon(
                      available
                          ? Icons.fingerprint_rounded
                          : Icons.lock_outline_rounded,
                      color: available ? AppColors.primary : AppColors.ink,
                      size: 68,
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    top: 18,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                available ? 'Masuk lebih cepat' : 'PIN tetap siap',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              Text(
                _availabilityMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.ink.withValues(alpha: 0.62),
                ),
              ),
              SizedBox(
                height: 52,
                child: _message == null
                    ? null
                    : Center(
                        child: Text(
                          _message!,
                          key: const Key('biometric-message'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('biometric-enable'),
                onPressed: available && !_isAuthenticating ? _activate : null,
                child: _isAuthenticating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.ink,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text('Aktifkan biometrik'),
              ),
              const SizedBox(height: 10),
              TextButton(
                key: const Key('biometric-use-pin'),
                onPressed: _isAuthenticating ? null : _skip,
                child: const Text('Tetap gunakan PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
