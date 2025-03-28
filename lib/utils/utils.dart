import 'package:flutter/material.dart';
import 'package:healthapp/models/health_record.dart';

class Utils {
  static Color getColorByRecordType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return Colors.red;
      case RecordType.bloodSugar:
        return Colors.blue;
      case RecordType.weight:
        return Colors.green;
      case RecordType.waistCircumference:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  static IconData getIconByRecordType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return Icons.favorite;
      case RecordType.bloodSugar:
        return Icons.water_drop;
      case RecordType.weight:
        return Icons.monitor_weight;
      case RecordType.waistCircumference:
        return Icons.straighten;
      default:
        return Icons.health_and_safety;
    }
  }

  static String getUnitByRecordType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return 'mmHg';
      case RecordType.bloodSugar:
        return 'mg/dL';
      case RecordType.weight:
        return 'kg';
      case RecordType.waistCircumference:
        return 'cm';
      default:
        return '';
    }
  }

  static String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
  }

  static String formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
