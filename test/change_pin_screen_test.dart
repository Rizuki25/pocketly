import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/features/security/presentation/change_pin_screen.dart';
import 'package:pocketly/features/security/presentation/pin_reauthentication_screen.dart';

void main() {
  testWidgets('change PIN verifies old PIN and stores confirmed strong PIN', (
    tester,
  ) async {
    final repository = _repository();
    await repository.createPin('135790');
    var changed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ChangePinScreen(
          pinRepository: repository,
          onChanged: () async => changed = true,
        ),
      ),
    );

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('change-pin-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Buat PIN baru'), findsOneWidget);

    await _enterPin(tester, '123456');
    await tester.tap(find.byKey(const Key('change-pin-continue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('change-pin-error')), findsOneWidget);

    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('change-pin-continue')));
    await tester.pumpAndSettle();
    expect(find.text('Ulangi PIN baru'), findsOneWidget);

    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('change-pin-continue')));
    await tester.pumpAndSettle();
    expect(find.text('PIN berhasil diubah'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pin-change-success-continue')));
    await tester.pumpAndSettle();

    expect(changed, isTrue);
    expect(
      (await repository.verifyPin('246802')).status,
      PinVerificationStatus.success,
    );
    expect(
      (await repository.verifyPin('135790')).status,
      PinVerificationStatus.incorrect,
    );
  });

  testWidgets('PIN reauthentication only returns success for correct PIN', (
    tester,
  ) async {
    final repository = _repository();
    await repository.createPin('135790');
    bool? verified;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                verified = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PinReauthenticationScreen(
                      pinRepository: repository,
                      title: 'Verifikasi PIN',
                      description: 'Konfirmasi tindakan sensitif.',
                    ),
                  ),
                );
              },
              child: const Text('Buka'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Buka'));
    await tester.pumpAndSettle();

    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('pin-reauthenticate')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-reauthentication-error')), findsOneWidget);
    expect(verified, isNull);

    await _enterPin(tester, '135790');
    await tester.tap(find.byKey(const Key('pin-reauthenticate')));
    await tester.pumpAndSettle();
    expect(verified, isTrue);
  });
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
}

PinAuthRepository _repository() => PinAuthRepository(
  store: MemorySecureKeyValueStore(),
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
