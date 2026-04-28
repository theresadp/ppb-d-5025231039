import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pitchmatch.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        targetPitch REAL,
        userPitch REAL,
        score REAL,
        date TEXT
      )
    ''');
  }

  Future<void> insertScore(Map<String, dynamic> data) async {
    final db = await instance.database;
    await db.insert('scores', data);
  }

  Future<List<Map<String, dynamic>>> getScores() async {
    final db = await instance.database;
    return await db.query('scores', orderBy: 'id DESC');
  }

  Future<void> deleteScore(int id) async {
    final db = await instance.database;
    await db.delete('scores', where: 'id = ?', whereArgs: [id]);
  }
}