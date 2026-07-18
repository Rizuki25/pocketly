import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_selector/file_selector.dart' hide XFile;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/files/share_cache_cleanup.dart';

abstract interface class BackupFileGateway {
  Future<bool> exportBackup({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  });

  Future<Uint8List?> pickBackup();
}

class SystemBackupFileGateway implements BackupFileGateway {
  const SystemBackupFileGateway();

  static const maxBackupSize = 20 * 1024 * 1024;

  @override
  Future<bool> exportBackup({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          title: 'Backup Pocketly',
          subject: 'Backup Pocketly terenkripsi',
          files: [XFile(file.path, mimeType: 'application/octet-stream')],
          fileNameOverrides: [fileName],
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
      scheduleShareCacheFileCleanup(
        temporaryDirectory: directory,
        fileName: fileName,
      );
      return result.status != ShareResultStatus.dismissed;
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  @override
  Future<Uint8List?> pickBackup() async {
    final temporaryDirectory = await getTemporaryDirectory();
    await cleanupStaleFilePickerCopies(temporaryDirectory);
    const typeGroup = XTypeGroup(
      label: 'Backup Pocketly',
      extensions: ['pocketly'],
      mimeTypes: ['application/octet-stream'],
      uniformTypeIdentifiers: ['public.data'],
    );
    final selected = await openFile(acceptedTypeGroups: [typeGroup]);
    if (selected == null) return null;
    final selectedFile = File(selected.path);
    try {
      final length = await selected.length();
      if (length <= 0 || length > maxBackupSize) {
        throw const FormatException('Ukuran file backup tidak valid.');
      }
      return await selected.readAsBytes();
    } finally {
      await deleteFileIfInsideDirectory(
        file: selectedFile,
        directory: temporaryDirectory,
      );
    }
  }
}
