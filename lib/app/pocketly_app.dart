import 'package:flutter/material.dart';

import '../core/security/biometric_authenticator.dart';
import '../core/security/biometric_preference_repository.dart';
import '../core/security/local_auth_biometric_authenticator.dart';
import '../core/security/pin_auth_repository.dart';
import '../core/security/secure_key_value_store.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/security/presentation/local_data_intro_screen.dart';
import '../features/security/presentation/biometric_offer_screen.dart';
import '../features/security/presentation/pin_lock_screen.dart';
import '../features/security/presentation/pin_setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'theme/app_theme.dart';

enum _AppStage {
  splash,
  onboarding,
  localData,
  pinSetup,
  biometricOffer,
  locked,
  unlocked,
  storageError,
}

class PocketlyApp extends StatefulWidget {
  const PocketlyApp({
    this.pinRepository,
    this.biometricPreferenceRepository,
    this.biometricAuthenticator,
    super.key,
  });

  final PinAuthRepository? pinRepository;
  final BiometricPreferenceRepository? biometricPreferenceRepository;
  final BiometricAuthenticator? biometricAuthenticator;

  @override
  State<PocketlyApp> createState() => _PocketlyAppState();
}

class _PocketlyAppState extends State<PocketlyApp> {
  _AppStage _stage = _AppStage.splash;
  late final PinAuthRepository _pinRepository;
  late final BiometricPreferenceRepository _biometricPreferenceRepository;
  late final BiometricAuthenticator _biometricAuthenticator;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    final secureStore = FlutterSecureKeyValueStore();
    _pinRepository =
        widget.pinRepository ?? PinAuthRepository(store: secureStore);
    _biometricPreferenceRepository =
        widget.biometricPreferenceRepository ??
        BiometricPreferenceRepository(store: secureStore);
    _biometricAuthenticator =
        widget.biometricAuthenticator ?? LocalAuthBiometricAuthenticator();
    _restoreSecurityState();
  }

  Future<void> _restoreSecurityState() async {
    try {
      final hasCredential = await _pinRepository.hasCredential();
      if (hasCredential) {
        _biometricEnabled = await _biometricPreferenceRepository.isEnabled();
        if (mounted) _setStage(_AppStage.locked);
      }
    } on Object {
      if (mounted) _setStage(_AppStage.storageError);
    }
  }

  void _setStage(_AppStage stage) => setState(() => _stage = stage);

  Future<void> _finishBiometricSetup() async {
    final enabled = await _biometricPreferenceRepository.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _stage = _AppStage.unlocked;
    });
  }

  Widget _buildStage() {
    return switch (_stage) {
      _AppStage.splash => SplashScreen(
        key: const ValueKey('splash'),
        onFinished: () => _setStage(_AppStage.onboarding),
      ),
      _AppStage.onboarding => OnboardingScreen(
        key: const ValueKey('onboarding'),
        onFinished: () => _setStage(_AppStage.localData),
      ),
      _AppStage.localData => LocalDataIntroScreen(
        key: const ValueKey('local-data'),
        onBack: () => _setStage(_AppStage.onboarding),
        onContinue: () => _setStage(_AppStage.pinSetup),
      ),
      _AppStage.pinSetup => PinSetupScreen(
        key: const ValueKey('pin-setup'),
        onBack: () => _setStage(_AppStage.localData),
        onCompleted: () => _setStage(_AppStage.biometricOffer),
        pinRepository: _pinRepository,
      ),
      _AppStage.biometricOffer => BiometricOfferScreen(
        key: const ValueKey('biometric-offer'),
        authenticator: _biometricAuthenticator,
        preferenceRepository: _biometricPreferenceRepository,
        onFinished: _finishBiometricSetup,
      ),
      _AppStage.locked => PinLockScreen(
        key: const ValueKey('pin-lock'),
        pinRepository: _pinRepository,
        biometricAuthenticator: _biometricAuthenticator,
        biometricEnabled: _biometricEnabled,
        onUnlocked: () => _setStage(_AppStage.unlocked),
      ),
      _AppStage.unlocked => _SecurityUnlockedView(
        key: ValueKey('security-unlocked'),
        biometricEnabled: _biometricEnabled,
        onConfigureBiometric: () => _setStage(_AppStage.biometricOffer),
      ),
      _AppStage.storageError => const _SecurityStorageErrorView(
        key: ValueKey('storage-error'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pocketly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _buildStage(),
      ),
    );
  }
}

class _SecurityUnlockedView extends StatelessWidget {
  const _SecurityUnlockedView({
    required this.biometricEnabled,
    required this.onConfigureBiometric,
    super.key,
  });

  final bool biometricEnabled;
  final VoidCallback onConfigureBiometric;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('security-unlocked-screen'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 54,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Akses berhasil',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'PIN terverifikasi. Beranda akan dibangun pada tahap berikutnya.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (biometricEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fingerprint_rounded),
                      SizedBox(width: 9),
                      Text(
                        'Biometrik aktif',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )
              else
                FilledButton.icon(
                  key: const Key('configure-biometric'),
                  onPressed: onConfigureBiometric,
                  icon: const Icon(Icons.fingerprint_rounded),
                  label: const Text('Aktifkan biometrik'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityStorageErrorView extends StatelessWidget {
  const _SecurityStorageErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('security-storage-error'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield_outlined, size: 54),
              const SizedBox(height: 20),
              Text(
                'Data keamanan tidak dapat dibuka',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Pocketly tidak membuat credential baru secara otomatis agar data lama tetap aman.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
