import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:healthapp/models/health_record.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'health_records.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE health_records(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type INTEGER NOT NULL,
        date INTEGER NOT NULL,
        record_values TEXT NOT NULL
      )
    ''');
  }

  // 건강 기록 저장
  Future<int> insertHealthRecord(HealthRecord record) async {
    Database db = await database;
    return await db.insert('health_records', record.toMap());
  }

  // 모든 건강 기록 가져오기
  Future<List<HealthRecord>> getAllHealthRecords() async {
    Database db = await database;
    List<Map<String, dynamic>> maps =
        await db.query('health_records', orderBy: 'date DESC');
    return List.generate(maps.length, (i) {
      return HealthRecord.fromMap(maps[i]);
    });
  }

  // 특정 유형의 건강 기록 가져오기
  Future<List<HealthRecord>> getHealthRecordsByType(RecordType type) async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query(
      'health_records',
      where: 'type = ?',
      whereArgs: [type.index],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return HealthRecord.fromMap(maps[i]);
    });
  }

  // 건강 기록 업데이트
  Future<int> updateHealthRecord(HealthRecord record) async {
    Database db = await database;
    return await db.update(
      'health_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

  // 건강 기록 삭제
  Future<int> deleteHealthRecord(int id) async {
    Database db = await database;
    return await db.delete(
      'health_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
