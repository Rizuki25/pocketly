import 'dart:async';
import 'dart:io';

void scheduleShareCacheFileCleanup({
  required Directory temporaryDirectory,
  required String fileName,
  Duration delay = const Duration(seconds: 30),
}) {
  unawaited(
    Future<void>.delayed(
      delay,
      () => deleteShareCacheFile(
        temporaryDirectory: temporaryDirectory,
        fileName: fileName,
      ),
    ),
  );
}

Future<void> deleteShareCacheFile({
  required Directory temporaryDirectory,
  required String fileName,
}) async {
  try {
    final file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}share_plus'
      '${Platform.pathSeparator}$fileName',
    );
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Cache sistem tetap akan dibersihkan Android atau share berikutnya.
  }
}

Future<void> cleanupShareCacheDirectory(Directory temporaryDirectory) async {
  try {
    final directory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}share_plus',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  } on FileSystemException {
    // Cache yang masih dipakai akan dicoba lagi saat aplikasi dibuka ulang.
  }
}

Future<void> cleanupStaleFilePickerCopies(Directory temporaryDirectory) async {
  try {
    if (!await temporaryDirectory.exists()) return;
    await for (final entity in temporaryDirectory.list(followLinks: false)) {
      if (entity is! Directory ||
          !_uuidDirectory.hasMatch(_name(entity.path))) {
        continue;
      }
      await entity.delete(recursive: true);
    }
  } on FileSystemException {
    // File cache dapat sedang dipakai sistem; percobaan berikutnya mengulang.
  }
}

Future<void> deleteFileIfInsideDirectory({
  required File file,
  required Directory directory,
}) async {
  try {
    if (!await file.exists() || !await directory.exists()) return;
    final root = await directory.resolveSymbolicLinks();
    final candidate = await file.resolveSymbolicLinks();
    final prefix = root.endsWith(Platform.pathSeparator)
        ? root
        : '$root${Platform.pathSeparator}';
    final normalizedRoot = Platform.isWindows ? prefix.toLowerCase() : prefix;
    final normalizedCandidate = Platform.isWindows
        ? candidate.toLowerCase()
        : candidate;
    if (normalizedCandidate.startsWith(normalizedRoot)) await file.delete();
  } on FileSystemException {
    // File asli di luar cache tidak boleh disentuh; cache gagal dapat diulang.
  }
}

final _uuidDirectory = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
  caseSensitive: false,
);

String _name(String path) =>
    path.split(RegExp(r'[/\\]')).where((part) => part.isNotEmpty).last;
