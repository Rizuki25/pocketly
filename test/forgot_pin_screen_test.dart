import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/security/biometric_authenticator.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/features/backup/data/backup_file_gateway.dart';
import 'package:pocketly/features/backup/data/backup_service.dart';
import 'package:pocketly/features/backup/data/encrypted_backup_codec.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';
import 'package:pocketly/features/security/presentation/forgot_pin_screen.dart';

void main() {
  testWidgets('successful biometric recovery creates a new PIN', (
    tester,
  ) async {
    final repository = _repository();
    await repository.createPin('135790');
    var resetCompleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPinScreen(
          pinRepository: repository,
          biometricAuthenticator: const _BiometricAuthenticator(
            status: BiometricAuthStatus.success,
          ),
          biometricEnabled: true,
          onPinReset: () async => resetCompleted = true,
          onResetLocalData: () async {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recover-with-biometric')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pin-reset-screen')), findsOneWidget);

    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('pin-reset-continue')));
    await tester.pumpAndSettle();
    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('pin-reset-continue')));
    await tester.pumpAndSettle();

    expect(resetCompleted, isTrue);
    expect(
      (await repository.verifyPin('246802')).status,
      PinVerificationStatus.success,
    );
    expect(
      (await repository.verifyPin('135790')).status,
      PinVerificationStatus.incorrect,
    );
  });

  testWidgets('failed biometric recovery keeps user on recovery screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPinScreen(
          pinRepository: _repository(),
          biometricAuthenticator: const _BiometricAuthenticator(
            status: BiometricAuthStatus.notRecognized,
          ),
          biometricEnabled: true,
          onPinReset: () async {},
          onResetLocalData: () async {},
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('recover-with-biometric')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('forgot-pin-screen')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(find.text('Biometrik belum dikenali. Coba lagi.'), findsOneWidget);
  });

  testWidgets('local reset requires both warning and typed confirmation', (
    tester,
  ) async {
    var resetCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPinScreen(
          pinRepository: _repository(),
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          biometricEnabled: false,
          onPinReset: () async {},
          onResetLocalData: () async => resetCalls++,
          onBack: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reset-local-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('local-reset-first-confirm')));
    await tester.pumpAndSettle();

    final finalButton = find.byKey(const Key('local-reset-final-confirm'));
    expect(tester.widget<FilledButton>(finalButton).onPressed, isNull);
    await tester.enterText(
      find.byKey(const Key('local-reset-confirmation-field')),
      'HAPUS',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(finalButton).onPressed, isNotNull);
    await tester.tap(finalButton);
    await tester.pumpAndSettle();

    expect(resetCalls, 1);
  });

  testWidgets('encrypted backup recovery restores data then creates new PIN', (
    tester,
  ) async {
    const codec = EncryptedBackupCodec(
      parameters: BackupKdfParameters(
        memory: 64,
        iterations: 1,
        parallelism: 1,
      ),
      useIsolate: false,
    );
    final source = MemoryGoalRepository();
    await source.create(_goal('restored-goal', 'Target dari backup'));
    final bytes = await BackupService(
      repository: source,
      codec: codec,
    ).create('rahasia-backup-ku');
    final target = MemoryGoalRepository();
    await target.create(_goal('old-goal', 'Target lama'));
    final pinRepository = _repository();
    await pinRepository.createPin('135790');
    var resetCompleted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ForgotPinScreen(
          pinRepository: pinRepository,
          biometricAuthenticator: const UnavailableBiometricAuthenticator(),
          biometricEnabled: false,
          onPinReset: () async => resetCompleted = true,
          onResetLocalData: () async {},
          onBack: () {},
          backupServiceProvider: () async =>
              BackupService(repository: target, codec: codec),
          backupFileGateway: _BackupFileGateway(bytes),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('recover-with-backup')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('restore-backup-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('backup-password-field')),
      'rahasia-backup-ku',
    );
    await tester.tap(find.byKey(const Key('backup-password-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-restore-backup')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pin-reset-screen')), findsOneWidget);
    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('pin-reset-continue')));
    await tester.pumpAndSettle();
    await _enterPin(tester, '246802');
    await tester.tap(find.byKey(const Key('pin-reset-continue')));
    await tester.pumpAndSettle();

    expect(resetCompleted, isTrue);
    expect((await target.getAll()).single.id, 'restored-goal');
    expect(
      (await pinRepository.verifyPin('246802')).status,
      PinVerificationStatus.success,
    );
  });
}

Future<void> _enterPin(WidgetTester tester, String pin) async {
  for (final digit in pin.split('')) {
    await tester.tap(find.byKey(Key('pin-key-$digit')));
    await tester.pump();
  }
}

PinAuthRepository _repository() => PinAuthRepository(
  store: MemorySecureKeyValueStore(),
  hasher: const PinHasher(
    useIsolate: false,
    parameters: PinKdfParameters(
      memory: 64,
      iterations: 1,
      parallelism: 1,
      hashLength: 16,
    ),
  ),
);

SavingsGoal _goal(String id, String name) {
  final now = DateTime.utc(2026, 7, 16);
  return SavingsGoal(
    id: id,
    name: name,
    targetAmount: 5000000,
    currentBalance: 1000000,
    frequency: SavingFrequency.monthly,
    status: SavingsGoalStatus.active,
    priority: 1,
    createdAt: now,
    updatedAt: now,
  );
}

class _BackupFileGateway implements BackupFileGateway {
  const _BackupFileGateway(this.bytes);

  final Uint8List bytes;

  @override
  Future<bool> exportBackup({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async => true;

  @override
  Future<Uint8List?> pickBackup() async => bytes;
}

class _BiometricAuthenticator implements BiometricAuthenticator {
  const _BiometricAuthenticator({required this.status});

  final BiometricAuthStatus status;

  @override
  Future<BiometricAvailability> checkAvailability() async =>
      BiometricAvailability.available;

  @override
  Future<BiometricAuthStatus> authenticate() async => status;
}
