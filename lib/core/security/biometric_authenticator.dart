enum BiometricAvailability { available, noHardware, notEnrolled, unavailable }

enum BiometricAuthStatus {
  success,
  notRecognized,
  cancelled,
  temporaryLockout,
  permanentLockout,
  unavailable,
  error,
}

abstract interface class BiometricAuthenticator {
  Future<BiometricAvailability> checkAvailability();

  Future<BiometricAuthStatus> authenticate();
}

class UnavailableBiometricAuthenticator implements BiometricAuthenticator {
  const UnavailableBiometricAuthenticator();

  @override
  Future<BiometricAvailability> checkAvailability() async =>
      BiometricAvailability.unavailable;

  @override
  Future<BiometricAuthStatus> authenticate() async =>
      BiometricAuthStatus.unavailable;
}
