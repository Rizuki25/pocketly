import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/app/pocketly_app.dart';
import 'package:pocketly/core/security/biometric_authenticator.dart';
import 'package:pocketly/core/security/biometric_preference_repository.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
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
    expect(find.byKey(const Key('security-unlocked-screen')), findsOneWidget);
    expect(await preferenceRepository.isEnabled(), isTrue);
  });

  testWidgets('existing credential opens the PIN lock screen', (tester) async {
    final store = MemorySecureKeyValueStore();
    final repository = _testRepository(store);
    await repository.createPin('135790');

    await tester.pumpWidget(_testApp(store: store, pinRepository: repository));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-lock-screen')), findsOneWidget);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-unlock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('security-unlocked-screen')), findsOneWidget);
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

    expect(find.byKey(const Key('security-unlocked-screen')), findsOneWidget);
    expect(authenticator.authenticateCalls, 1);
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
  );
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
