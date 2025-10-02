import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

final dbProvider = FutureProvider<Database>((ref) async {
  final AppDatabase database = AppDatabase();
  return database.openDatabase();
});

class AppDatabase {
  static const String _dbName = 'offline_cards.db';
  static const int _dbVersion = 1;

  Future<Database> openDatabase() async {
    final String databasesPath = await getDatabasesPath();
    final String path = p.join(databasesPath, _dbName);
    return openDbAtPath(path);
  }

  Future<Database> openDbAtPath(String path) {
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (Database db, int version) async {
        await _createSchema(db);
      },
    );
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE decks(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE cards(
        id TEXT PRIMARY KEY,
        deck_id TEXT NOT NULL,
        front TEXT NOT NULL,
        back TEXT NOT NULL,
        tags TEXT NOT NULL,
        ease REAL NOT NULL,
        interval INTEGER NOT NULL,
        due INTEGER NOT NULL,
        reps INTEGER NOT NULL,
        lapses INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY(deck_id) REFERENCES decks(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('CREATE INDEX idx_cards_deck_id ON cards(deck_id);');
    await db.execute('CREATE INDEX idx_cards_due ON cards(due);');
  }
}
