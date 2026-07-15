abstract final class PinPolicy {
  static String? validate(String pin) {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      return 'Masukkan 6 digit PIN.';
    }

    if (pin.split('').every((digit) => digit == pin[0])) {
      return 'PIN dengan angka yang sama terlalu mudah ditebak.';
    }

    if (_isSequential(pin)) {
      return 'Hindari urutan angka yang mudah ditebak.';
    }

    if (pin.substring(0, 3) == pin.substring(3)) {
      return 'Hindari pola angka yang berulang.';
    }

    return null;
  }

  static bool _isSequential(String pin) {
    final digits = pin.codeUnits.map((unit) => unit - 48).toList();
    final ascending = List.generate(
      digits.length - 1,
      (index) => digits[index + 1] - digits[index] == 1,
    ).every((value) => value);
    final descending = List.generate(
      digits.length - 1,
      (index) => digits[index + 1] - digits[index] == -1,
    ).every((value) => value);
    return ascending || descending;
  }
}
