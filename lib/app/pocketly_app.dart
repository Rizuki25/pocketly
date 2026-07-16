import 'dart:async';

import 'package:flutter/material.dart';

import '../core/security/biometric_authenticator.dart';
import '../core/security/biometric_preference_repository.dart';
import '../core/security/local_auth_biometric_authenticator.dart';
import '../core/security/pin_auth_repository.dart';
import '../core/security/secure_key_value_store.dart';
import '../core/security/screen_privacy_controller.dart';
import '../core/database/database_encryption_key_repository.dart';
import '../core/database/pocketly_database.dart';
import '../features/dashboard/presentation/main_shell.dart';
import '../features/goals/data/goal_repository.dart';
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
    this.screenPrivacyController,
    this.goalRepository,
    this.autoLockDuration = const Duration(minutes: 1),
    this.now,
    super.key,
  });

  final PinAuthRepository? pinRepository;
  final BiometricPreferenceRepository? biometricPreferenceRepository;
  final BiometricAuthenticator? biometricAuthenticator;
  final ScreenPrivacyController? screenPrivacyController;
  final GoalRepository? goalRepository;
  final Duration autoLockDuration;
  final DateTime Function()? now;

  @override
  State<PocketlyApp> createState() => _PocketlyAppState();
}

class _PocketlyAppState extends State<PocketlyApp> with WidgetsBindingObserver {
  _AppStage _stage = _AppStage.splash;
  late final PinAuthRepository _pinRepository;
  late final BiometricPreferenceRepository _biometricPreferenceRepository;
  late final BiometricAuthenticator _biometricAuthenticator;
  late final ScreenPrivacyController _screenPrivacyController;
  late final SecureKeyValueStore _secureStore;
  Future<GoalRepository>? _goalRepositoryFuture;
  bool _biometricEnabled = false;
  bool _sessionUnlocked = false;
  DateTime? _backgroundedAt;
  bool _routeSensitive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final secureStore = FlutterSecureKeyValueStore();
    _secureStore = secureStore;
    _pinRepository =
        widget.pinRepository ?? PinAuthRepository(store: secureStore);
    _biometricPreferenceRepository =
        widget.biometricPreferenceRepository ??
        BiometricPreferenceRepository(store: secureStore);
    _biometricAuthenticator =
        widget.biometricAuthenticator ?? LocalAuthBiometricAuthenticator();
    _screenPrivacyController =
        widget.screenPrivacyController ??
        const MethodChannelScreenPrivacyController();
    _applyScreenPrivacy(_stage);
    _restoreSecurityState();
  }

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_sessionUnlocked) {
          _backgroundedAt ??= _now();
        }
      case AppLifecycleState.resumed:
        _lockAfterBackgroundTimeout();
      case AppLifecycleState.detached:
        _backgroundedAt = null;
        if (_sessionUnlocked && mounted) {
          setState(() {
            _sessionUnlocked = false;
            _stage = _AppStage.locked;
          });
          _applyScreenPrivacy(_AppStage.locked);
        }
    }
  }

  void _lockAfterBackgroundTimeout() {
    final backgroundedAt = _backgroundedAt;
    _backgroundedAt = null;
    if (!_sessionUnlocked || backgroundedAt == null || !mounted) return;

    final elapsed = _now().difference(backgroundedAt);
    if (elapsed.isNegative || elapsed >= widget.autoLockDuration) {
      setState(() {
        _sessionUnlocked = false;
        _stage = _AppStage.locked;
      });
      _applyScreenPrivacy(_AppStage.locked);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final repository = _goalRepositoryFuture;
    if (repository != null) {
      unawaited(_closeGoalRepository(repository));
    }
    super.dispose();
  }

  Future<void> _closeGoalRepository(Future<GoalRepository> repository) async {
    try {
      await (await repository).close();
    } on Object {
      // Kegagalan membuka database sudah ditangani oleh layar error.
    }
  }

  Future<GoalRepository> _getGoalRepository() {
    return _goalRepositoryFuture ??= _createGoalRepository();
  }

  Future<GoalRepository> _createGoalRepository() async {
    final injected = widget.goalRepository;
    if (injected != null) return injected;
    final database = await PocketlyDatabase.open(
      keyRepository: DatabaseEncryptionKeyRepository(store: _secureStore),
    );
    return SqlCipherGoalRepository(database);
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

  void _setStage(_AppStage stage) {
    setState(() => _stage = stage);
    _applyScreenPrivacy(stage);
  }

  void _applyScreenPrivacy(_AppStage stage) {
    final stageSensitive = switch (stage) {
      _AppStage.pinSetup ||
      _AppStage.biometricOffer ||
      _AppStage.locked => true,
      _ => false,
    };
    unawaited(
      _screenPrivacyController.setSensitiveScreen(
        stageSensitive || _routeSensitive,
      ),
    );
  }

  void _setRouteSensitive(bool sensitive) {
    _routeSensitive = sensitive;
    _applyScreenPrivacy(_stage);
  }

  Future<void> _finishSecurityChange() async {
    try {
      await _biometricPreferenceRepository.setEnabled(false);
    } on Object {
      if (!mounted) return;
      setState(() {
        _sessionUnlocked = false;
        _backgroundedAt = null;
        _stage = _AppStage.storageError;
      });
      _applyScreenPrivacy(_AppStage.storageError);
      return;
    }
    if (!mounted) return;
    setState(() {
      _biometricEnabled = false;
      _sessionUnlocked = false;
      _backgroundedAt = null;
      _stage = _AppStage.locked;
    });
    _applyScreenPrivacy(_AppStage.locked);
  }

  Future<void> _finishBiometricSetup() async {
    final enabled = await _biometricPreferenceRepository.isEnabled();
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _sessionUnlocked = true;
      _stage = _AppStage.unlocked;
    });
    _applyScreenPrivacy(_AppStage.unlocked);
  }

  void _completePinSetup() {
    setState(() {
      _sessionUnlocked = true;
      _stage = _AppStage.biometricOffer;
    });
    _applyScreenPrivacy(_AppStage.biometricOffer);
  }

  void _unlock() {
    setState(() {
      _sessionUnlocked = true;
      _backgroundedAt = null;
      _stage = _AppStage.unlocked;
    });
    _applyScreenPrivacy(_AppStage.unlocked);
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
        onCompleted: _completePinSetup,
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
        onUnlocked: _unlock,
      ),
      _AppStage.unlocked => FutureBuilder<GoalRepository>(
        key: const ValueKey('main-shell-stage'),
        future: _getGoalRepository(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _DatabaseErrorView();
          }
          final repository = snapshot.data;
          if (repository == null) return const _DatabaseLoadingView();
          return MainShell(
            biometricEnabled: _biometricEnabled,
            onConfigureBiometric: () => _setStage(_AppStage.biometricOffer),
            pinRepository: _pinRepository,
            onSecurityChanged: _finishSecurityChange,
            onSensitiveScreenChanged: _setRouteSensitive,
            goalRepository: repository,
          );
        },
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

class _DatabaseLoadingView extends StatelessWidget {
  const _DatabaseLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('database-loading-screen'),
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DatabaseErrorView extends StatelessWidget {
  const _DatabaseErrorView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('database-error-screen'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storage_rounded, size: 54),
              const SizedBox(height: 20),
              Text(
                'Data tabungan tidak dapat dibuka',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              const Text(
                'Pocketly tidak membuat database kosong secara otomatis agar data lama tetap aman.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
