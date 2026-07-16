import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/app/pocketly_app.dart';
import 'package:pocketly/core/security/biometric_authenticator.dart';
import 'package:pocketly/core/security/biometric_preference_repository.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/core/security/screen_privacy_controller.dart';
import 'package:pocketly/features/security/presentation/biometric_offer_screen.dart';

void main() {
  testWidgets('splash opens the first onboarding page', (tester) async {
    await tester.pumpWidget(_testApp());

    expect(find.byKey(const Key('splash-screen')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-screen')), findsOneWidget);
    expect(find.text('Rencana kecil,\nhasil yang berarti.'), findsOneWidget);
  });

  testWidgets('onboarding advances through all pages', (tester) async {
    await tester.pumpWidget(_testApp());
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Setiap langkah\nlayak dirayakan.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('Tetap privat.\nTetap milikmu.'), findsOneWidget);
    expect(find.text('Mulai sekarang'), findsOneWidget);
  });

  testWidgets('local data explanation leads to a validated PIN setup', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final preferenceRepository = BiometricPreferenceRepository(store: store);
    await tester.pumpWidget(
      _testApp(
        store: store,
        biometricPreferenceRepository: preferenceRepository,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mulai sekarang'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('local-data-screen')), findsOneWidget);
    await tester.tap(find.byKey(const Key('local-data-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-setup-screen')), findsOneWidget);

    await _enterPin(tester, '123456');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-error')), findsOneWidget);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Ulangi PIN-mu'), findsOneWidget);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-success-title')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pin-success-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('biometric-offer-screen')), findsOneWidget);

    await tester.tap(find.byKey(const Key('biometric-enable')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('main-shell')), findsOneWidget);
    expect(await preferenceRepository.isEnabled(), isTrue);
  });

  testWidgets('existing credential opens the PIN lock screen', (tester) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    final screenPrivacyController = _FakeScreenPrivacyController();
    await repository.createPin('135790');

    await tester.pumpWidget(
      _testApp(
        store: store,
        pinRepository: repository,
        screenPrivacyController: screenPrivacyController,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-lock-screen')), findsOneWidget);
    expect(screenPrivacyController.lastValue, isTrue);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-unlock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('main-shell')), findsOneWidget);
    expect(screenPrivacyController.lastValue, isFalse);
  });

  testWidgets('unlocked app locks after one minute in background', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    var now = DateTime(2026, 7, 16, 10);
    await repository.createPin('135790');

    await tester.pumpWidget(
      _testApp(store: store, pinRepository: repository, now: () => now),
    );
    await tester.pumpAndSettle();
    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-unlock')));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pin-lock-screen')), findsOneWidget);
  });

  testWidgets('unlocked app stays open before auto-lock timeout', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    var now = DateTime(2026, 7, 16, 10);
    await repository.createPin('135790');

    await tester.pumpWidget(
      _testApp(store: store, pinRepository: repository, now: () => now),
    );
    await tester.pumpAndSettle();
    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-unlock')));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 59));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-shell')), findsOneWidget);
  });

  testWidgets('enabled biometric authenticates once automatically', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    final preferenceRepository = BiometricPreferenceRepository(store: store);
    final authenticator = _FakeBiometricAuthenticator(
      authResults: [BiometricAuthStatus.success],
    );
    await repository.createPin('135790');
    await preferenceRepository.setEnabled(true);

    await tester.pumpWidget(
      _testApp(
        store: store,
        pinRepository: repository,
        biometricPreferenceRepository: preferenceRepository,
        biometricAuthenticator: authenticator,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('main-shell')), findsOneWidget);
    expect(authenticator.authenticateCalls, 1);
  });

  testWidgets('main navigation opens all primary sections', (tester) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    await repository.createPin('135790');

    await tester.pumpWidget(_testApp(store: store, pinRepository: repository));
    await tester.pumpAndSettle();
    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-unlock')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-page')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dashboard-create-goal')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-target')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('goals-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-add')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-reports')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reports-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile-page')), findsOneWidget);
  });

  testWidgets('cancelled biometric stays on lock screen without a loop', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    final preferenceRepository = BiometricPreferenceRepository(store: store);
    final authenticator = _FakeBiometricAuthenticator(
      authResults: [
        BiometricAuthStatus.cancelled,
        BiometricAuthStatus.notRecognized,
      ],
    );
    await repository.createPin('135790');
    await preferenceRepository.setEnabled(true);

    await tester.pumpWidget(
      _testApp(
        store: store,
        pinRepository: repository,
        biometricPreferenceRepository: preferenceRepository,
        biometricAuthenticator: authenticator,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pin-lock-screen')), findsOneWidget);
    expect(authenticator.authenticateCalls, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(authenticator.authenticateCalls, 1);

    await tester.tap(find.byKey(const Key('biometric-retry')));
    await tester.pumpAndSettle();
    expect(authenticator.authenticateCalls, 2);
  });

  testWidgets('not enrolled biometric keeps PIN as a usable fallback', (
    tester,
  ) async {
    final store = MemorySecureKeyValueStore();
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: BiometricOfferScreen(
          authenticator: _FakeBiometricAuthenticator(
            availability: BiometricAvailability.notEnrolled,
            authResults: [BiometricAuthStatus.unavailable],
          ),
          preferenceRepository: BiometricPreferenceRepository(store: store),
          onFinished: () => finished = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Belum ada sidik jari'), findsOneWidget);
    await tester.tap(find.byKey(const Key('biometric-use-pin')));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
}

PinAuthRepository _testRepository([MemorySecureKeyValueStore? store]) {
  return PinAuthRepository(
    store: store ?? MemorySecureKeyValueStore(),
    hasher: const PinHasher(
      useIsolate: false,
      parameters: PinKdfParameters(
        memory: 64,
        iterations: 1,
        parallelism: 1,
        hashLength: 16,
      ),
    ),
  );
}

PocketlyApp _testApp({
  MemorySecureKeyValueStore? store,
  PinAuthRepository? pinRepository,
  BiometricPreferenceRepository? biometricPreferenceRepository,
  BiometricAuthenticator? biometricAuthenticator,
  ScreenPrivacyController? screenPrivacyController,
  DateTime Function()? now,
}) {
  final actualStore = store ?? MemorySecureKeyValueStore();
  return PocketlyApp(
    pinRepository: pinRepository ?? _testRepository(actualStore),
    biometricPreferenceRepository:
        biometricPreferenceRepository ??
        BiometricPreferenceRepository(store: actualStore),
    biometricAuthenticator:
        biometricAuthenticator ??
        _FakeBiometricAuthenticator(authResults: [BiometricAuthStatus.success]),
    screenPrivacyController:
        screenPrivacyController ?? _FakeScreenPrivacyController(),
    now: now,
  );
}

class _FakeScreenPrivacyController implements ScreenPrivacyController {
  final values = <bool>[];

  bool? get lastValue => values.lastOrNull;

  @override
  Future<void> setSensitiveScreen(bool sensitive) async {
    values.add(sensitive);
  }
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  _FakeBiometricAuthenticator({
    this.availability = BiometricAvailability.available,
    required List<BiometricAuthStatus> authResults,
  }) : _authResults = List.of(authResults);

  final BiometricAvailability availability;
  final List<BiometricAuthStatus> _authResults;
  int authenticateCalls = 0;

  @override
  Future<BiometricAvailability> checkAvailability() async => availability;

  @override
  Future<BiometricAuthStatus> authenticate() async {
    final result =
        _authResults[authenticateCalls.clamp(0, _authResults.length - 1)];
    authenticateCalls++;
    return result;
  }
}
