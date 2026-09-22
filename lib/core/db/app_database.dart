import 'package:sembast/sembast.dart';

/// How to open the local database on this platform (or in tests).
class DatabaseConfig {
  const DatabaseConfig({required this.factory, required this.path});

  final DatabaseFactory factory;
  final Future<String> Function() path;
}

/// Opens the sembast database once and shares the connection.
class AppDatabase {
  AppDatabase(this.config);

  final DatabaseConfig config;
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async =>
      config.factory.openDatabase(await config.path(), version: 1);

  Future<void> close() async {
    final pending = _opening;
    if (pending == null) return;
    _opening = null;
    final db = await pending;
    await db.close();
  }
}
