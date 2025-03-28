import 'package:intl/intl.dart';

enum RecordType {
  bloodPressure,
  bloodSugar,
  weight,
  waistCircumference,
  history,
}

class HealthRecord {
  final int? id;
  final RecordType type;
  final DateTime date;
  final Map<String, dynamic> recordValues;

  HealthRecord({
    this.id,
    required this.type,
    required this.date,
    required this.recordValues,
  });

  // JSON 변환 메서드
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'date': date.millisecondsSinceEpoch,
      'record_values': recordValues.toString(),
    };
  }

  // JSON에서 객체 생성
  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'],
      type: RecordType.values[map['type']],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      recordValues: _parseValues(map['record_values']),
    );
  }

  // 문자열로 저장된 values를 파싱
  static Map<String, dynamic> _parseValues(String valuesStr) {
    // 단순 파싱 예제, 실제로는 더 견고한 파싱 필요
    Map<String, dynamic> result = {};
    String cleanStr = valuesStr.replaceAll('{', '').replaceAll('}', '');
    List<String> pairs = cleanStr.split(',');

    for (var pair in pairs) {
      List<String> keyValue = pair.split(':');
      if (keyValue.length == 2) {
        String key = keyValue[0].trim();
        String value = keyValue[1].trim();
        result[key] = value;
      }
    }

    return result;
  }

  // 기록 유형에 따른 표시명 가져오기
  static String getTypeName(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return '혈압';
      case RecordType.bloodSugar:
        return '혈당';
      case RecordType.weight:
        return '체중';
      case RecordType.waistCircumference:
        return '허리둘레';
      case RecordType.history:
        return '건강 기록 이력';
    }
  }

  // 날짜 형식화
  String getFormattedDate() {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  // 요약 정보 가져오기 (표시용)
  String getSummary() {
    switch (type) {
      case RecordType.bloodPressure:
        return '${recordValues['systolic']}/${recordValues['diastolic']} mmHg';
      case RecordType.bloodSugar:
        return '${recordValues['value']} mg/dL';
      case RecordType.weight:
        return '${recordValues['value']} kg';
      case RecordType.waistCircumference:
        return '${recordValues['value']} cm';
      case RecordType.history:
        return '건강 기록 이력';
    }
  }

  // 날짜와 함께 요약 반환
  String getSummaryWithDate() {
    return DateFormat('yyyy년 MM월 dd일 HH:mm', 'ko').format(date);
  }
}
