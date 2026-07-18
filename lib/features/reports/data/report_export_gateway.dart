import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/files/share_cache_cleanup.dart';

abstract interface class ReportExportGateway {
  Future<bool> exportCsv({
    required Uint8List bytes,
    required String fileName,
    Rect? sharePositionOrigin,
  });
}

class SystemReportExportGateway implements ReportExportGateway {
  const SystemReportExportGateway();

  @override
  Future<bool> exportCsv({
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
          title: 'Ekspor laporan Pocketly',
          subject: 'Laporan transaksi Pocketly',
          text: 'File CSV ini tidak terenkripsi. Simpan di lokasi yang aman.',
          files: [XFile(file.path, mimeType: 'text/csv')],
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
}
