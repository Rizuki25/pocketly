import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/features/security/domain/pin_policy.dart';

void main() {
  group('PinPolicy', () {
    test('accepts a non-trivial six digit PIN', () {
      expect(PinPolicy.validate('135790'), isNull);
    });

    test('rejects repeated digits', () {
      expect(PinPolicy.validate('111111'), isNotNull);
    });

    test('rejects sequential digits', () {
      expect(PinPolicy.validate('123456'), isNotNull);
      expect(PinPolicy.validate('654321'), isNotNull);
    });

    test('rejects a repeated pattern', () {
      expect(PinPolicy.validate('123123'), isNotNull);
    });
  });
}
