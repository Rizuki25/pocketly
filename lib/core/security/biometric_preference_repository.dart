import 'secure_key_value_store.dart';

class BiometricPreferenceRepository {
  const BiometricPreferenceRepository({required SecureKeyValueStore store})
    : _store = store;

  static const _enabledKey = 'security.biometric_enabled.v1';

  final SecureKeyValueStore _store;

  Future<bool> isEnabled() async => await _store.read(_enabledKey) == 'true';

  Future<void> setEnabled(bool enabled) =>
      _store.write(_enabledKey, enabled.toString());
}
