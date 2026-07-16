import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';

void main() {
  late MemorySecureKeyValueStore store;
  late DateTime now;
  late PinAuthRepository repository;

  setUp(() {
    store = MemorySecureKeyValueStore();
    now = DateTime.utc(2026, 7, 16, 10);
    repository = _repository(store: store, clock: () => now);
  });

  test(
    'stores only a salted credential and verifies the correct PIN',
    () async {
      await repository.createPin('135790');

      expect(await repository.hasCredential(), isTrue);
      expect(store.values.values.join(), isNot(contains('135790')));
      expect(
        (await repository.verifyPin('135790')).status,
        PinVerificationStatus.success,
      );
      expect(
        (await repository.verifyPin('246802')).status,
        PinVerificationStatus.incorrect,
      );
    },
  );

  test('applies persistent progressive lockout after five failures', () async {
    await repository.createPin('135790');

    for (var attempt = 1; attempt <= 4; attempt++) {
      final result = await repository.verifyPin('246802');
      expect(result.status, PinVerificationStatus.incorrect);
      expect(result.failedAttempts, attempt);
    }

    final fifth = await repository.verifyPin('246802');
    expect(fifth.status, PinVerificationStatus.locked);
    expect(fifth.retryAfter, const Duration(seconds: 30));

    final restoredRepository = _repository(store: store, clock: () => now);
    final restored = await restoredRepository.verifyPin('135790');
    expect(restored.status, PinVerificationStatus.locked);

    now = now.add(const Duration(seconds: 31));
    final sixth = await restoredRepository.verifyPin('246802');
    expect(sixth.status, PinVerificationStatus.locked);
    expect(sixth.retryAfter, const Duration(minutes: 1));
  });

  test('successful verification resets the failure counter', () async {
    await repository.createPin('135790');
    await repository.verifyPin('246802');
    await repository.verifyPin('246802');

    expect(
      (await repository.verifyPin('135790')).status,
      PinVerificationStatus.success,
    );
    final nextFailure = await repository.verifyPin('246802');
    expect(nextFailure.failedAttempts, 1);
  });
}

PinAuthRepository _repository({
  required MemorySecureKeyValueStore store,
  required DateTime Function() clock,
}) {
  return PinAuthRepository(
    store: store,
    clock: clock,
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
