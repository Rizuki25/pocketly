import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../goals/domain/savings_goal.dart';
import '../../transactions/domain/savings_transaction.dart';
import '../domain/backup_data.dart';

class BackupKdfParameters {
  const BackupKdfParameters({
    required this.memory,
    required this.iterations,
    required this.parallelism,
  });

  static const production = BackupKdfParameters(
    memory: 19 * 1024,
    iterations: 2,
    parallelism: 1,
  );

  final int memory;
  final int iterations;
  final int parallelism;
}

class EncryptedBackupCodec {
  const EncryptedBackupCodec({
    this.parameters = BackupKdfParameters.production,
    this.useIsolate = true,
  });

  final BackupKdfParameters parameters;
  final bool useIsolate;

  Future<Uint8List> encrypt(BackupData data, String password) {
    if (password.length < 10) {
      throw const BackupException('Kata sandi backup minimal 10 karakter.');
    }
    final payload = _encodePayload(data);
    if (useIsolate) {
      return Isolate.run(() => _encryptDirect(payload, password, parameters));
    }
    return _encryptDirect(payload, password, parameters);
  }

  Future<BackupData> decrypt(Uint8List fileBytes, String password) async {
    if (password.isEmpty) {
      throw const BackupException('Kata sandi backup wajib diisi.');
    }
    try {
      final clearBytes = useIsolate
          ? await Isolate.run(
              () => _decryptDirect(fileBytes, password, parameters),
            )
          : await _decryptDirect(fileBytes, password, parameters);
      return _decodePayload(clearBytes);
    } on BackupException {
      rethrow;
    } on Object {
      throw const BackupException('Kata sandi salah atau file backup rusak.');
    }
  }
}

const _format = 'pocketly-encrypted-backup';
const _formatVersion = 1;
const _payloadVersion = 1;
const _aadText = 'pocketly-encrypted-backup-v1';

Future<Uint8List> _encryptDirect(
  Uint8List clearBytes,
  String password,
  BackupKdfParameters parameters,
) async {
  final random = Random.secure();
  final salt = List<int>.generate(16, (_) => random.nextInt(256));
  final nonce = List<int>.generate(12, (_) => random.nextInt(256));
  final key = await _deriveKey(password, salt, parameters);
  final box = await AesGcm.with256bits().encrypt(
    clearBytes,
    secretKey: key,
    nonce: nonce,
    aad: utf8.encode(_aadText),
  );
  final envelope = <String, Object>{
    'format': _format,
    'version': _formatVersion,
    'kdf': <String, Object>{
      'algorithm': 'argon2id',
      'memory': parameters.memory,
      'iterations': parameters.iterations,
      'parallelism': parameters.parallelism,
      'salt': base64UrlEncode(salt),
    },
    'cipher': <String, Object>{
      'algorithm': 'aes-256-gcm',
      'nonce': base64UrlEncode(box.nonce),
      'ciphertext': base64UrlEncode(box.cipherText),
      'mac': base64UrlEncode(box.mac.bytes),
    },
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
}

Future<Uint8List> _decryptDirect(
  Uint8List fileBytes,
  String password,
  BackupKdfParameters expectedParameters,
) async {
  final envelope = jsonDecode(utf8.decode(fileBytes)) as Map<String, Object?>;
  if (envelope['format'] != _format || envelope['version'] != _formatVersion) {
    throw const BackupException('Format backup tidak didukung.');
  }
  final kdf = envelope['kdf']! as Map<String, Object?>;
  final cipherData = envelope['cipher']! as Map<String, Object?>;
  if (kdf['algorithm'] != 'argon2id' ||
      kdf['memory'] != expectedParameters.memory ||
      kdf['iterations'] != expectedParameters.iterations ||
      kdf['parallelism'] != expectedParameters.parallelism ||
      cipherData['algorithm'] != 'aes-256-gcm') {
    throw const BackupException('Parameter keamanan backup tidak didukung.');
  }
  final salt = base64Url.decode(kdf['salt']! as String);
  final nonce = base64Url.decode(cipherData['nonce']! as String);
  final ciphertext = base64Url.decode(cipherData['ciphertext']! as String);
  final mac = base64Url.decode(cipherData['mac']! as String);
  if (salt.length != 16 || nonce.length != 12 || mac.length != 16) {
    throw const BackupException('Struktur backup tidak valid.');
  }
  final key = await _deriveKey(password, salt, expectedParameters);
  final clearBytes = await AesGcm.with256bits().decrypt(
    SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
    secretKey: key,
    aad: utf8.encode(_aadText),
  );
  return Uint8List.fromList(clearBytes);
}

Future<SecretKey> _deriveKey(
  String password,
  List<int> salt,
  BackupKdfParameters parameters,
) {
  return Argon2id(
    memory: parameters.memory,
    iterations: parameters.iterations,
    parallelism: parameters.parallelism,
    hashLength: 32,
  ).deriveKeyFromPassword(password: password, nonce: salt);
}

Uint8List _encodePayload(BackupData data) {
  final payload = <String, Object>{
    'version': _payloadVersion,
    'createdAt': data.createdAt.toUtc().toIso8601String(),
    'goals': data.goals.map(_goalToJson).toList(growable: false),
    'transactions': data.transactions
        .map(_transactionToJson)
        .toList(growable: false),
  };
  return Uint8List.fromList(utf8.encode(jsonEncode(payload)));
}

BackupData _decodePayload(Uint8List clearBytes) {
  try {
    final payload = jsonDecode(utf8.decode(clearBytes)) as Map<String, Object?>;
    if (payload['version'] != _payloadVersion) {
      throw const BackupException('Versi isi backup tidak didukung.');
    }
    final goals = (payload['goals']! as List<Object?>)
        .map((value) => _goalFromJson(value! as Map<String, Object?>))
        .toList(growable: false);
    final transactions = (payload['transactions']! as List<Object?>)
        .map((value) => _transactionFromJson(value! as Map<String, Object?>))
        .toList(growable: false);
    return BackupData(
      createdAt: DateTime.parse(payload['createdAt']! as String).toUtc(),
      goals: goals,
      transactions: transactions,
    );
  } on BackupException {
    rethrow;
  } on Object {
    throw const BackupException('Isi backup tidak valid.');
  }
}

Map<String, Object?> _goalToJson(SavingsGoal goal) => {
  'id': goal.id,
  'name': goal.name,
  'targetAmount': goal.targetAmount,
  'currentBalance': goal.currentBalance,
  'frequency': goal.frequency.name,
  'status': goal.status.name,
  'priority': goal.priority,
  'createdAt': goal.createdAt.toUtc().toIso8601String(),
  'updatedAt': goal.updatedAt.toUtc().toIso8601String(),
  'deadline': goal.deadline?.toUtc().toIso8601String(),
  'category': goal.category,
  'archivedAt': goal.archivedAt?.toUtc().toIso8601String(),
  'completedAt': goal.completedAt?.toUtc().toIso8601String(),
};

SavingsGoal _goalFromJson(Map<String, Object?> json) => SavingsGoal(
  id: json['id']! as String,
  name: json['name']! as String,
  targetAmount: json['targetAmount']! as int,
  currentBalance: json['currentBalance']! as int,
  frequency: SavingFrequency.values.byName(json['frequency']! as String),
  status: SavingsGoalStatus.values.byName(json['status']! as String),
  priority: json['priority']! as int,
  createdAt: DateTime.parse(json['createdAt']! as String),
  updatedAt: DateTime.parse(json['updatedAt']! as String),
  deadline: _optionalDate(json['deadline']),
  category: json['category'] as String?,
  archivedAt: _optionalDate(json['archivedAt']),
  completedAt: _optionalDate(json['completedAt']),
);

Map<String, Object?> _transactionToJson(SavingsTransaction transaction) => {
  'id': transaction.id,
  'goalId': transaction.goalId,
  'type': transaction.type.name,
  'amount': transaction.amount,
  'occurredAt': transaction.occurredAt.toUtc().toIso8601String(),
  'createdAt': transaction.createdAt.toUtc().toIso8601String(),
  'updatedAt': transaction.updatedAt.toUtc().toIso8601String(),
  'source': transaction.source,
  'note': transaction.note,
};

SavingsTransaction _transactionFromJson(Map<String, Object?> json) =>
    SavingsTransaction(
      id: json['id']! as String,
      goalId: json['goalId']! as String,
      type: SavingsTransactionType.values.byName(json['type']! as String),
      amount: json['amount']! as int,
      occurredAt: DateTime.parse(json['occurredAt']! as String),
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      source: json['source'] as String?,
      note: json['note'] as String?,
    );

DateTime? _optionalDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);
