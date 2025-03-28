import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:flutter/foundation.dart';

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
  Future<List<HealthRecord>> getAllHealthRecords(
      {int? startTime, int? endTime}) async {
    Database db = await database;

    try {
      List<Map<String, dynamic>> maps;

      if (startTime != null && endTime != null) {
        // 날짜 범위가 제공된 경우 rawQuery 사용
        String query = '''
          SELECT * FROM health_records 
          WHERE date BETWEEN ? AND ? 
          ORDER BY date DESC
        ''';
        debugPrint('실행 SQL: $query');
        debugPrint('파라미터: [$startTime, $endTime]');
        maps = await db.rawQuery(query, [startTime, endTime]);
      } else {
        // 범위가 없는 경우 표준 query 사용
        maps = await db.query(
          'health_records',
          orderBy: 'date DESC',
        );
      }

      debugPrint('getAllHealthRecords: 조회된 레코드 수: ${maps.length}');

      return List.generate(maps.length, (i) {
        return HealthRecord.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('getAllHealthRecords 오류: $e');
      return [];
    }
  }

  // 특정 유형의 건강 기록 가져오기
  Future<List<HealthRecord>> getHealthRecordsByType(RecordType type) async {
    Database db = await database;
    try {
      List<Map<String, dynamic>> maps = await db.query(
        'health_records',
        where: 'type = ?',
        whereArgs: [type.index],
        orderBy: 'date DESC',
      );

      debugPrint(
          'getHealthRecordsByType(${type.toString()}): 조회된 레코드 수: ${maps.length}');

      return List.generate(maps.length, (i) {
        return HealthRecord.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('getHealthRecordsByType 오류: $e');
      return [];
    }
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

  // 날짜 범위로 건강 기록 조회
  Future<List<HealthRecord>> getRecordsByDateRange(
      int startTime, int endTime) async {
    final db = await database;

    try {
      // 올바른 SQL 쿼리 작성
      final query = '''
        SELECT * FROM health_records 
        WHERE date BETWEEN ? AND ? 
        ORDER BY date DESC
      ''';

      debugPrint('실행 SQL: $query');
      debugPrint('파라미터: [$startTime, $endTime]');

      final List<Map<String, dynamic>> maps =
          await db.rawQuery(query, [startTime, endTime]);

      debugPrint('조회된 레코드 수: ${maps.length}');

      return List.generate(maps.length, (i) {
        return HealthRecord.fromMap(maps[i]);
      });
    } catch (e) {
      debugPrint('getRecordsByDateRange 오류: $e');
      return [];
    }
  }

  // 유형과 날짜 범위로 건강 기록 조회
  Future<List<HealthRecord>> getHealthRecordsByTypeAndDateRange(
      RecordType type, int startTime, int endTime) async {
    final db = await database;

    String query = '''
      SELECT * FROM health_records 
      WHERE type = ? AND date BETWEEN ? AND ? 
      ORDER BY date ASC
    ''';

    final List<Map<String, dynamic>> maps =
        await db.rawQuery(query, [type.index, startTime, endTime]);

    debugPrint(
        '건강 기록 조회: 유형=${type.index}, 시작=${startTime}, 종료=${endTime}, 결과 개수=${maps.length}');

    return List.generate(maps.length, (i) {
      return HealthRecord.fromMap(maps[i]);
    });
  }
}
