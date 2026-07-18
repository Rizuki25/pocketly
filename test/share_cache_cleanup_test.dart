import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pocketly/core/files/share_cache_cleanup.dart';

void main() {
  test('share cache cleanup only deletes the selected Pocketly file', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'pocketly-share-cache-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final shareDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}share_plus',
    );
    await shareDirectory.create();
    final selected = File(
      '${shareDirectory.path}${Platform.pathSeparator}laporan.csv',
    );
    final unrelated = File(
      '${shareDirectory.path}${Platform.pathSeparator}file-lain.txt',
    );
    await selected.writeAsString('data');
    await unrelated.writeAsString('tetap');

    await deleteShareCacheFile(
      temporaryDirectory: temporaryDirectory,
      fileName: 'laporan.csv',
    );

    expect(await selected.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });

  test('file picker cleanup removes UUID cache folders only', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'pocketly-picker-cache-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final pickerDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      '07a5732f-2d64-3ee0-bbb5-1a2be0d710e2',
    );
    final unrelatedDirectory = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}image-cache',
    );
    await pickerDirectory.create();
    await unrelatedDirectory.create();
    await File(
      '${pickerDirectory.path}${Platform.pathSeparator}backup.bin',
    ).writeAsString('backup');

    await cleanupStaleFilePickerCopies(temporaryDirectory);

    expect(await pickerDirectory.exists(), isFalse);
    expect(await unrelatedDirectory.exists(), isTrue);
  });

  test('owned-file cleanup never deletes a source outside cache', () async {
    final parent = await Directory.systemTemp.createTemp(
      'pocketly-owned-cache-',
    );
    addTearDown(() async {
      if (await parent.exists()) await parent.delete(recursive: true);
    });
    final cache = Directory('${parent.path}${Platform.pathSeparator}cache');
    await cache.create();
    final cached = File('${cache.path}${Platform.pathSeparator}backup.bin');
    final source = File('${parent.path}${Platform.pathSeparator}source.bin');
    await cached.writeAsString('cache');
    await source.writeAsString('source');

    await deleteFileIfInsideDirectory(file: cached, directory: cache);
    await deleteFileIfInsideDirectory(file: source, directory: cache);

    expect(await cached.exists(), isFalse);
    expect(await source.exists(), isTrue);
  });

  test('startup share cleanup removes only the share_plus directory', () async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'pocketly-startup-cache-',
    );
    addTearDown(() async {
      if (await temporaryDirectory.exists()) {
        await temporaryDirectory.delete(recursive: true);
      }
    });
    final share = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}share_plus',
    );
    final unrelated = Directory(
      '${temporaryDirectory.path}${Platform.pathSeparator}image-cache',
    );
    await share.create();
    await unrelated.create();
    await File(
      '${share.path}${Platform.pathSeparator}laporan.csv',
    ).writeAsString('data');

    await cleanupShareCacheDirectory(temporaryDirectory);

    expect(await share.exists(), isFalse);
    expect(await unrelated.exists(), isTrue);
  });
}
