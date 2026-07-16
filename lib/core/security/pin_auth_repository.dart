import 'pin_credential.dart';
import 'pin_hasher.dart';
import 'secure_key_value_store.dart';

enum PinVerificationStatus {
  success,
  incorrect,
  locked,
  notConfigured,
  credentialCorrupted,
}

class PinVerificationResult {
  const PinVerificationResult({
    required this.status,
    this.failedAttempts = 0,
    this.retryAfter = Duration.zero,
  });

  final PinVerificationStatus status;
  final int failedAttempts;
  final Duration retryAfter;
}

class PinAuthRepository {
  PinAuthRepository({
    required SecureKeyValueStore store,
    PinHasher hasher = const PinHasher(),
    DateTime Function()? clock,
  }) : _store = store,
       _hasher = hasher,
       _clock = clock ?? DateTime.now;

  static const _credentialKey = 'security.pin_credential.v1';

  final SecureKeyValueStore _store;
  final PinHasher _hasher;
  final DateTime Function() _clock;

  Future<bool> hasCredential() async {
    final encoded = await _store.read(_credentialKey);
    if (encoded == null) return false;
    PinCredential.decode(encoded);
    return true;
  }

  Future<void> deleteCredential() => _store.delete(_credentialKey);

  Future<void> createPin(String pin) async {
    final result = await _hasher.hash(pin);
    final credential = PinCredential(
      hash: result.hash,
      salt: result.salt,
      parameters: _hasher.parameters,
      failedAttempts: 0,
      lockedUntil: null,
      pinChangedAt: _clock().toUtc(),
    );
    await _store.write(_credentialKey, credential.encode());
  }

  Future<PinVerificationResult> verifyPin(String pin) async {
    final encoded = await _store.read(_credentialKey);
    if (encoded == null) {
      return const PinVerificationResult(
        status: PinVerificationStatus.notConfigured,
      );
    }

    late final PinCredential credential;
    try {
      credential = PinCredential.decode(encoded);
    } on FormatException {
      return const PinVerificationResult(
        status: PinVerificationStatus.credentialCorrupted,
      );
    }

    final now = _clock().toUtc();
    final lockedUntil = credential.lockedUntil;
    if (lockedUntil != null && lockedUntil.isAfter(now)) {
      return PinVerificationResult(
        status: PinVerificationStatus.locked,
        failedAttempts: credential.failedAttempts,
        retryAfter: lockedUntil.difference(now),
      );
    }

    final matches = await _hasher.verify(
      pin: pin,
      expectedHash: credential.hash,
      encodedSalt: credential.salt,
      parameters: credential.parameters,
    );
    if (matches) {
      if (credential.failedAttempts != 0 || credential.lockedUntil != null) {
        await _store.write(
          _credentialKey,
          credential
              .copyWith(failedAttempts: 0, clearLockedUntil: true)
              .encode(),
        );
      }
      return const PinVerificationResult(status: PinVerificationStatus.success);
    }

    final failedAttempts = credential.failedAttempts + 1;
    final lockDuration = _lockDurationFor(failedAttempts);
    final updated = credential.copyWith(
      failedAttempts: failedAttempts,
      lockedUntil: lockDuration == Duration.zero ? null : now.add(lockDuration),
      clearLockedUntil: lockDuration == Duration.zero,
    );
    await _store.write(_credentialKey, updated.encode());

    return PinVerificationResult(
      status: lockDuration == Duration.zero
          ? PinVerificationStatus.incorrect
          : PinVerificationStatus.locked,
      failedAttempts: failedAttempts,
      retryAfter: lockDuration,
    );
  }

  static Duration _lockDurationFor(int failedAttempts) {
    return switch (failedAttempts) {
      < 5 => Duration.zero,
      5 => const Duration(seconds: 30),
      6 => const Duration(minutes: 1),
      7 => const Duration(minutes: 5),
      _ => const Duration(minutes: 15),
    };
  }
}
