import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:healthapp/models/health_record.dart';
import 'package:go_router/go_router.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  final Function(String) onTextRecognized;
  final Function(RecordType) onRecordTypeDetected;
  final BuildContext context;

  SpeechRecognitionService({
    required this.context,
    required this.onTextRecognized,
    required this.onRecordTypeDetected,
  });

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  Future<bool> initialize() async {
    final bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done') {
          _isListening = false;
          _analyzeRecognizedText();
        }
      },
      onError: (error) {
        _isListening = false;
        print('음성 인식 오류: $error');
      },
    );
    return available;
  }

  Future<void> startListening() async {
    if (!_isListening) {
      bool available = await initialize();
      if (available) {
        _isListening = true;
        await _speech.listen(
          onResult: (result) {
            _recognizedText = result.recognizedWords;
            onTextRecognized(_recognizedText);
          },
          localeId: 'ko_KR',
        );
      } else {
        print('음성 인식 기능을 사용할 수 없습니다.');
      }
    }
  }

  void stopListening() {
    if (_isListening) {
      _speech.stop();
      _isListening = false;
    }
  }

  void _analyzeRecognizedText() {
    final String text = _recognizedText.toLowerCase();

    // 특정 키워드 감지
    if (text.contains('혈압') || text.contains('혈압 측정')) {
      onRecordTypeDetected(RecordType.bloodPressure);
      _navigateToRecordScreen(RecordType.bloodPressure);
    } else if (text.contains('혈당') ||
        text.contains('당뇨') ||
        text.contains('혈당 측정')) {
      onRecordTypeDetected(RecordType.bloodSugar);
      _navigateToRecordScreen(RecordType.bloodSugar);
    } else if (text.contains('체중') ||
        text.contains('몸무게') ||
        text.contains('체중 측정')) {
      onRecordTypeDetected(RecordType.weight);
      _navigateToRecordScreen(RecordType.weight);
    } else if (text.contains('허리') ||
        text.contains('허리둘레') ||
        text.contains('허리 측정')) {
      onRecordTypeDetected(RecordType.waistCircumference);
      _navigateToRecordScreen(RecordType.waistCircumference);
    } else if (text.contains('기록') ||
        text.contains('이력') ||
        text.contains('히스토리')) {
      context.push('/history');
    }
  }

  void _navigateToRecordScreen(RecordType type) {
    context.push('/record/${type.index}');
  }
}
