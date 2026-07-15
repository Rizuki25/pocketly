import 'package:flutter/material.dart';

import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/security/presentation/local_data_intro_screen.dart';
import '../features/security/presentation/pin_setup_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import 'theme/app_theme.dart';

enum _AppStage { splash, onboarding, localData, pinSetup }

class PocketlyApp extends StatefulWidget {
  const PocketlyApp({super.key});

  @override
  State<PocketlyApp> createState() => _PocketlyAppState();
}

class _PocketlyAppState extends State<PocketlyApp> {
  _AppStage _stage = _AppStage.splash;

  void _setStage(_AppStage stage) => setState(() => _stage = stage);

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
