import 'dart:convert';
import 'dart:math';

import '../security/secure_key_value_store.dart';

class DatabaseEncryptionKeyRepository {
  DatabaseEncryptionKeyRepository({required SecureKeyValueStore store})
    : _store = store;

  static const _storageKey = 'pocketly_database_key_v1';
  static const _keyLength = 32;

  final SecureKeyValueStore _store;

  Future<String> getOrCreateKey() async {
    final stored = await _store.read(_storageKey);
    if (stored != null) {
      try {
        final bytes = base64Url.decode(base64Url.normalize(stored));
        if (bytes.length != _keyLength) throw const FormatException();
        return stored;
      } on FormatException {
        throw StateError('Kunci database tidak dapat dibuka dengan aman.');
      }
    }

    final random = Random.secure();
    final bytes = List<int>.generate(_keyLength, (_) => random.nextInt(256));
    final encoded = base64UrlEncode(bytes);
    await _store.write(_storageKey, encoded);
    return encoded;
  }

  Future<void> deleteKey() => _store.delete(_storageKey);
}
