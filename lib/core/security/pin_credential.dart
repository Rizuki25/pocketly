import 'dart:convert';

class PinKdfParameters {
  const PinKdfParameters({
    required this.memory,
    required this.iterations,
    required this.parallelism,
    required this.hashLength,
  });

  static const production = PinKdfParameters(
    memory: 19 * 1024,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  );

  final int memory;
  final int iterations;
  final int parallelism;
  final int hashLength;

  Map<String, Object> toJson() => {
    'memory': memory,
    'iterations': iterations,
    'parallelism': parallelism,
    'hashLength': hashLength,
  };

  factory PinKdfParameters.fromJson(Map<String, Object?> json) {
    return PinKdfParameters(
      memory: json['memory']! as int,
      iterations: json['iterations']! as int,
      parallelism: json['parallelism']! as int,
      hashLength: json['hashLength']! as int,
    );
  }
}

class PinCredential {
  const PinCredential({
    required this.hash,
    required this.salt,
    required this.parameters,
    required this.failedAttempts,
    required this.lockedUntil,
    required this.pinChangedAt,
  });

  static const schemaVersion = 1;
  static const algorithm = 'argon2id';

  final String hash;
  final String salt;
  final PinKdfParameters parameters;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime pinChangedAt;

  PinCredential copyWith({
    int? failedAttempts,
    DateTime? lockedUntil,
    bool clearLockedUntil = false,
  }) {
    return PinCredential(
      hash: hash,
      salt: salt,
      parameters: parameters,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: clearLockedUntil ? null : lockedUntil ?? this.lockedUntil,
      pinChangedAt: pinChangedAt,
    );
  }

  String encode() => jsonEncode({
    'version': schemaVersion,
    'algorithm': algorithm,
    'hash': hash,
    'salt': salt,
    'parameters': parameters.toJson(),
    'failedAttempts': failedAttempts,
    'lockedUntil': lockedUntil?.toUtc().toIso8601String(),
    'pinChangedAt': pinChangedAt.toUtc().toIso8601String(),
  });

  factory PinCredential.decode(String encoded) {
    final json = jsonDecode(encoded) as Map<String, Object?>;
    if (json['version'] != schemaVersion || json['algorithm'] != algorithm) {
      throw const FormatException('Unsupported PIN credential format.');
    }
    return PinCredential(
      hash: json['hash']! as String,
      salt: json['salt']! as String,
      parameters: PinKdfParameters.fromJson(
        json['parameters']! as Map<String, Object?>,
      ),
      failedAttempts: json['failedAttempts']! as int,
      lockedUntil: json['lockedUntil'] == null
          ? null
          : DateTime.parse(json['lockedUntil']! as String).toUtc(),
      pinChangedAt: DateTime.parse(json['pinChangedAt']! as String).toUtc(),
    );
  }
}
