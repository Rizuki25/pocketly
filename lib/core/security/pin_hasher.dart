import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'pin_credential.dart';

class PinHashResult {
  const PinHashResult({required this.hash, required this.salt});

  final String hash;
  final String salt;
}

class PinHasher {
  const PinHasher({
    this.parameters = PinKdfParameters.production,
    this.useIsolate = true,
  });

  final PinKdfParameters parameters;
  final bool useIsolate;

  Future<PinHashResult> hash(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final bytes = await _derive(pin, salt, parameters);
    return PinHashResult(
      hash: base64UrlEncode(bytes),
      salt: base64UrlEncode(salt),
    );
  }

  Future<bool> verify({
    required String pin,
    required String expectedHash,
    required String encodedSalt,
    required PinKdfParameters parameters,
  }) async {
    final actual = await _derive(
      pin,
      base64Url.decode(encodedSalt),
      parameters,
    );
    final expected = base64Url.decode(expectedHash);
    return _constantTimeEquals(actual, expected);
  }

  Future<List<int>> _derive(
    String pin,
    List<int> salt,
    PinKdfParameters parameters,
  ) {
    if (useIsolate) {
      return Isolate.run(() => _deriveDirect(pin, salt, parameters));
    }
    return _deriveDirect(pin, salt, parameters);
  }

  static Future<List<int>> _deriveDirect(
    String pin,
    List<int> salt,
    PinKdfParameters parameters,
  ) async {
    final algorithm = Argon2id(
      memory: parameters.memory,
      iterations: parameters.iterations,
      parallelism: parameters.parallelism,
      hashLength: parameters.hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: pin,
      nonce: salt,
    );
    return key.extractBytes();
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    var difference = left.length ^ right.length;
    final length = min(left.length, right.length);
    for (var index = 0; index < length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}
