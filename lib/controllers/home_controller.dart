import 'package:flutter/material.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/database/database_helper.dart';

class HomeController extends ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<HealthRecord> _todayRecords = [];
  bool _isLoadingRecords = true;

  // Getters
  List<HealthRecord> get todayRecords => _todayRecords;
  bool get isLoadingRecords => _isLoadingRecords;

  // 초기화
  HomeController() {
    loadTodayRecords();
  }

  // 오늘 날짜의 건강 기록 로드
  Future<void> loadTodayRecords() async {
    try {
      _isLoadingRecords = true;
      notifyListeners();

      // 오늘 날짜 기준으로 00:00:00부터 23:59:59까지의 레코드만 조회
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(milliseconds: 1));

      // 시간 범위 디버깅
      debugPrint(
          '데이터 조회 범위: ${startOfDay.toString()} ~ ${endOfDay.toString()}');
      debugPrint(
          '타임스탬프: ${startOfDay.millisecondsSinceEpoch} ~ ${endOfDay.millisecondsSinceEpoch}');

      // 수정된 메서드 호출
      final records = await _dbHelper.getRecordsByDateRange(
          startOfDay.millisecondsSinceEpoch, endOfDay.millisecondsSinceEpoch);

      _todayRecords = records;
      _isLoadingRecords = false;
      notifyListeners();
    } catch (e) {
      _isLoadingRecords = false;
      notifyListeners();
      debugPrint('오류 발생: $e');
    }
  }

  // 특정 유형의 최근 기록 가져오기
  HealthRecord? getLatestRecordByType(RecordType type) {
    final filteredRecords =
        _todayRecords.where((record) => record.type == type).toList();

    if (filteredRecords.isEmpty) {
      return null;
    }

    // 시간별로 정렬하여 가장 최근 기록 반환
    filteredRecords.sort((a, b) => b.date.compareTo(a.date));
    return filteredRecords.first;
  }

  // 기록 유형별 색상 반환
  Color getColorForRecordType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return Colors.red.shade400;
      case RecordType.bloodSugar:
        return Colors.purple.shade400;
      case RecordType.weight:
        return Colors.blue.shade400;
      case RecordType.waistCircumference:
        return Colors.green.shade400;
      case RecordType.history:
        return Colors.grey.shade400;
    }
  }

  // 기록 유형별 아이콘 반환
  IconData getIconForRecordType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return Icons.favorite;
      case RecordType.bloodSugar:
        return Icons.water_drop;
      case RecordType.weight:
        return Icons.monitor_weight;
      case RecordType.waistCircumference:
        return Icons.straighten;
      case RecordType.history:
        return Icons.history;
    }
  }

  // 최종 업데이트 시간 포맷
  String formatLastUpdateTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else {
      return '${difference.inDays}일 전';
    }
  }

  String getFormattedValue(HealthRecord record) {
    switch (record.type) {
      case RecordType.bloodPressure:
        return '${record.recordValues['systolic']} / ${record.recordValues['diastolic']}';
      case RecordType.bloodSugar:
        return '${record.recordValues['value']} mg/dL';
      case RecordType.weight:
        return '${record.recordValues['value']} kg';
      case RecordType.waistCircumference:
        return '${record.recordValues['value']} cm';
      case RecordType.history:
        return '건강 기록 이력';
    }
  }
}
