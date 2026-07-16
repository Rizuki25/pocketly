import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/security/pin_auth_repository.dart';
import 'package:pocketly/core/security/pin_credential.dart';
import 'package:pocketly/core/security/pin_hasher.dart';
import 'package:pocketly/core/security/secure_key_value_store.dart';
import 'package:pocketly/features/backup/data/backup_file_gateway.dart';
import 'package:pocketly/features/backup/data/backup_service.dart';
import 'package:pocketly/features/backup/data/encrypted_backup_codec.dart';
import 'package:pocketly/features/backup/presentation/backup_screen.dart';
import 'package:pocketly/features/goals/data/goal_repository.dart';
import 'package:pocketly/features/goals/domain/savings_goal.dart';

void main() {
  const codec = EncryptedBackupCodec(
    parameters: BackupKdfParameters(memory: 64, iterations: 1, parallelism: 1),
    useIsolate: false,
  );

  testWidgets(
    'creating backup validates password then exports encrypted file',
    (tester) async {
      final repository = MemoryGoalRepository();
      await repository.create(_goal('goal-1', 'Dana darurat'));
      final gateway = _BackupFileGateway();
      await tester.pumpWidget(
        MaterialApp(
          home: BackupScreen(
            service: BackupService(repository: repository, codec: codec),
            fileGateway: gateway,
            pinRepository: _pinRepository(),
            onRestored: () async {},
            requirePinAuthentication: false,
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('create-backup-action')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('backup-password-field')),
        'pendek',
      );
      await tester.enterText(
        find.byKey(const Key('backup-password-confirmation-field')),
        'pendek',
      );
      await tester.tap(find.byKey(const Key('backup-password-submit')));
      await tester.pump();
      expect(find.byKey(const Key('backup-password-error')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('backup-password-field')),
        'rahasia-backup-ku',
      );
      await tester.enterText(
        find.byKey(const Key('backup-password-confirmation-field')),
        'rahasia-backup-ku',
      );
      await tester.tap(find.byKey(const Key('backup-password-submit')));
      await tester.pumpAndSettle();

    expect(gateway.exportedBytes, isNotNull);
    expect(gateway.exportedFileName, endsWith('.pocketly'));
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Backup terenkripsi siap disimpan.'), findsOneWidget);
      final decoded = await codec.decrypt(
        gateway.exportedBytes!,
        'rahasia-backup-ku',
      );
      expect(decoded.goals.single.name, 'Dana darurat');
    },
  );

  testWidgets('restore requires confirmation and replaces current data', (
    tester,
  ) async {
    final source = MemoryGoalRepository();
    await source.create(_goal('restored-goal', 'Target dari backup'));
    final bytes = await BackupService(
      repository: source,
      codec: codec,
    ).create('rahasia-backup-ku');
    final target = MemoryGoalRepository();
    await target.create(_goal('old-goal', 'Target lama'));
    final gateway = _BackupFileGateway(importedBytes: bytes);
    var reloadCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(
          service: BackupService(repository: target, codec: codec),
          fileGateway: gateway,
          pinRepository: _pinRepository(),
          onRestored: () async => reloadCalls++,
          requirePinAuthentication: false,
          allowCreate: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('restore-backup-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('backup-password-field')),
      'rahasia-backup-ku',
    );
    await tester.tap(find.byKey(const Key('backup-password-submit')));
    await tester.pumpAndSettle();

    expect((await target.getAll()).single.id, 'old-goal');
    await tester.tap(find.byKey(const Key('confirm-restore-backup')));
    await tester.pumpAndSettle();

    expect((await target.getAll()).single.id, 'restored-goal');
    expect(reloadCalls, 1);
    expect(find.text('Backup berhasil dipulihkan.'), findsOneWidget);
  });

  testWidgets('wrong backup password does not replace current data', (
    tester,
  ) async {
    final source = MemoryGoalRepository();
    await source.create(_goal('restored-goal', 'Target dari backup'));
    final bytes = await BackupService(
      repository: source,
      codec: codec,
    ).create('rahasia-backup-ku');
    final target = MemoryGoalRepository();
    await target.create(_goal('old-goal', 'Target lama'));
    await tester.pumpWidget(
      MaterialApp(
        home: BackupScreen(
          service: BackupService(repository: target, codec: codec),
          fileGateway: _BackupFileGateway(importedBytes: bytes),
          pinRepository: _pinRepository(),
          onRestored: () async {},
          requirePinAuthentication: false,
          allowCreate: false,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('restore-backup-action')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('backup-password-field')),
      'kata-sandi-salah',
    );
    await tester.tap(find.byKey(const Key('backup-password-submit')));
    await tester.pumpAndSettle();

    expect((await target.getAll()).single.id, 'old-goal');
    expect(
      find.text('Kata sandi salah atau file backup rusak.'),
      findsOneWidget,
    );
  });
}

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

PinAuthRepository _pinRepository() => PinAuthRepository(
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

class _BackupFileGateway implements BackupFileGateway {
  _BackupFileGateway({this.importedBytes});

  final Uint8List? importedBytes;
  Uint8List? exportedBytes;
  String? exportedFileName;

  @override
  Future<bool> exportBackup({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    exportedBytes = bytes;
    exportedFileName = fileName;
    return true;
  }

  @override
  Future<Uint8List?> pickBackup() async => importedBytes;
}
