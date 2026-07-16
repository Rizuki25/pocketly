import 'package:local_auth/local_auth.dart';

import 'biometric_authenticator.dart';

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator({LocalAuthentication? localAuthentication})
    : _localAuthentication = localAuthentication ?? LocalAuthentication();

  final LocalAuthentication _localAuthentication;

  @override
  Future<BiometricAvailability> checkAvailability() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      if (!canCheck) return BiometricAvailability.noHardware;

      final enrolled = await _localAuthentication.getAvailableBiometrics();
      if (enrolled.isEmpty) return BiometricAvailability.notEnrolled;
      return BiometricAvailability.available;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAvailability.notEnrolled,
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricAvailability.noHardware,
        _ => BiometricAvailability.unavailable,
      };
    } on Object {
      return BiometricAvailability.unavailable;
    }
  }

  @override
  Future<BiometricAuthStatus> authenticate() async {
    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Verifikasi identitas untuk membuka Pocketly',
        biometricOnly: true,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: false,
      );
      return authenticated
          ? BiometricAuthStatus.success
          : BiometricAuthStatus.notRecognized;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.userRequestedFallback ||
        LocalAuthExceptionCode.timeout => BiometricAuthStatus.cancelled,
        LocalAuthExceptionCode.temporaryLockout =>
          BiometricAuthStatus.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthStatus.permanentLockout,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet ||
        LocalAuthExceptionCode.noBiometricHardware ||
        LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
          BiometricAuthStatus.unavailable,
        _ => BiometricAuthStatus.error,
      };
    } on Object {
      return BiometricAuthStatus.error;
    }
  }
}
