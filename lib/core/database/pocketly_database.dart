import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'database_encryption_key_repository.dart';

class PocketlyDatabase {
  PocketlyDatabase._(this.database);

  static const schemaVersion = 1;
  static const fileName = 'pocketly_encrypted.db';

  final Database database;

  static Future<PocketlyDatabase> open({
    required DatabaseEncryptionKeyRepository keyRepository,
  }) async {
    final password = await keyRepository.getOrCreateKey();
    final databasesPath = await getDatabasesPath();
    final database = await openDatabase(
      path.join(databasesPath, fileName),
      password: password,
      version: schemaVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _createSchema,
    );

    final cipher = await database.rawQuery('PRAGMA cipher_version');
    if (cipher.isEmpty) {
      await database.close();
      throw StateError('Database terenkripsi tidak tersedia pada perangkat.');
    }
    return PocketlyDatabase._(database);
  }

  static Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL CHECK (length(trim(name)) > 0),
        target_amount INTEGER NOT NULL CHECK (target_amount > 0),
        current_balance INTEGER NOT NULL DEFAULT 0 CHECK (current_balance >= 0),
        frequency TEXT NOT NULL,
        deadline INTEGER,
        category TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'active',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        archived_at INTEGER,
        completed_at INTEGER,
        CHECK (status IN ('active', 'completed', 'archived')),
        CHECK (frequency IN ('daily', 'weekly', 'monthly', 'flexible'))
      )
    ''');
    await db.execute(
      'CREATE INDEX goals_status_priority_idx '
      'ON goals (status, priority DESC, updated_at DESC)',
    );
  }

  Future<void> close() => database.close();
}
