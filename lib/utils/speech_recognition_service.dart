import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:healthapp/models/health_record.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _recognizedText = '';
  String _lastAnalyzedText = ''; // 마지막으로 분석한 텍스트를 저장
  final Function(String) onTextRecognized;
  final Function(RecordType) onRecordTypeDetected;
  final BuildContext context;
  stt.LocaleName? _selectedLocale;

  // 타이머 추가
  bool _timeoutOccurred = false;

  // 상태 변경을 알리는 콜백 추가
  final Function(bool) onListeningStateChanged;

  // 키워드 매칭 결과 콜백 추가
  final Function(List<RecordType>) onKeywordsDetected;

  SpeechRecognitionService({
    required this.context,
    required this.onTextRecognized,
    required this.onRecordTypeDetected,
    required this.onListeningStateChanged,
    required this.onKeywordsDetected,
  });

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  // 오류 발생 시 사용자에게 안내
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('음성 인식 오류'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // 한국어 로케일 찾기
  Future<stt.LocaleName?> _findKoreanLocale() async {
    var locales = await _speech.locales();
    developer.log(
        '사용 가능한 모든 언어: ${locales.map((e) => "${e.localeId} (${e.name})").join(', ')}',
        name: 'Speech');

    // 정확한 'ko_KR' 먼저 찾기
    var koreanLocale =
        locales.where((locale) => locale.localeId == 'ko_KR').toList();

    // 'ko_KR'이 없으면 'ko'로 시작하는 로케일 찾기
    if (koreanLocale.isEmpty) {
      koreanLocale =
          locales.where((locale) => locale.localeId.startsWith('ko')).toList();
    }

    // 한국어 로케일이 있으면 반환
    if (koreanLocale.isNotEmpty) {
      developer.log('한국어 로케일 찾음: ${koreanLocale.first.localeId}',
          name: 'Speech');
      return koreanLocale.first;
    }

    // 없으면 null 반환 (기본 로케일 사용)
    developer.log('한국어 로케일을 찾을 수 없음, 기본 로케일 사용', name: 'Speech');
    return null;
  }

  Future<bool> initialize() async {
    try {
      developer.log('음성 인식 초기화 시작', name: 'Speech');
      final bool available = await _speech.initialize(
        onStatus: (status) {
          developer.log('음성 인식 상태: $status', name: 'Speech');

          // 모든 상태 변화를 로깅
          if (status == 'done' || status == 'notListening') {
            developer.log('음성 인식 종료 감지: $status', name: 'Speech');

            // 종료 시 상태를 업데이트하기 전에 현재 인식된 텍스트를 분석합니다
            if (_recognizedText.isNotEmpty) {
              developer.log('상태 변경 전 최종 텍스트: $_recognizedText', name: 'Speech');
              _lastAnalyzedText = _recognizedText; // 최종 텍스트 저장
              _analyzeRecognizedText();
            } else {
              developer.log('인식된 텍스트 없음 (상태 변경)', name: 'Speech');
            }

            // 상태 업데이트는 텍스트 분석 후에 수행
            _isListening = false;
            onListeningStateChanged(false);
          } else if (status == 'listening') {
            developer.log('음성 인식 시작 감지', name: 'Speech');
            _timeoutOccurred = false;
            onListeningStateChanged(true);
          }
        },
        onError: (error) {
          developer.log('음성 인식 오류: ${error.errorMsg}', name: 'Speech');
          _isListening = false;
          if (error.errorMsg.contains('permission') ||
              error.errorMsg.contains('권한')) {
            _showErrorDialog('음성 인식을 사용하려면 마이크 권한이 필요합니다. 앱 설정에서 권한을 허용해주세요.');
          }
        },
      );

      if (available) {
        // 한국어 로케일 찾기
        _selectedLocale = await _findKoreanLocale();
        developer.log(
            '음성 인식 초기화 성공: 선택된 로케일 = ${_selectedLocale?.localeId ?? "기본값"}',
            name: 'Speech');
      } else {
        developer.log('음성 인식 초기화 실패', name: 'Speech');
      }

      return available;
    } catch (e) {
      developer.log('음성 인식 초기화 예외 발생: $e', name: 'Speech');
      return false;
    }
  }

  Future<void> startListening() async {
    // 이미 듣고 있는 상태라면 중지
    if (_isListening) {
      await stopListening();
      // 약간의 지연 추가
      await Future.delayed(const Duration(milliseconds: 200));
    }

    bool available = await initialize();
    if (available) {
      _isListening = true;
      onListeningStateChanged(true);
      _timeoutOccurred = false;
      _recognizedText = '';
      _lastAnalyzedText = '';

      try {
        developer.log('음성 인식 시작: 로케일=${_selectedLocale?.localeId ?? "ko_KR"}',
            name: 'Speech');
        await _speech.listen(
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          onResult: (result) {
            if (result.recognizedWords.isNotEmpty) {
              _recognizedText = result.recognizedWords;
              onTextRecognized(_recognizedText);
              developer.log('인식된 텍스트 (실시간): $_recognizedText', name: 'Speech');
            }
          },
          localeId: _selectedLocale?.localeId ?? 'ko_KR',
        );

        // 15초 후에 자동으로 중지 (안전장치)
        Future.delayed(const Duration(seconds: 15), () {
          if (_isListening) {
            developer.log('15초 타임아웃: 음성 인식 자동 종료', name: 'Speech');
            _timeoutOccurred = true;
            stopListening();
          }
        });
      } catch (e) {
        developer.log('음성 인식 시작 오류: $e', name: 'Speech');
        _isListening = false;
      }
    } else {
      developer.log('음성 인식 기능을 사용할 수 없습니다.', name: 'Speech');
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speech.stop();
        developer.log('음성 인식 중지 요청 완료', name: 'Speech');
      } catch (e) {
        developer.log('음성 인식 중지 오류: $e', name: 'Speech');
      } finally {
        // 타임아웃이 아닌 경우이고, 아직 분석되지 않은 텍스트가 있다면 분석
        if (!_timeoutOccurred &&
            _recognizedText.isNotEmpty &&
            _recognizedText != _lastAnalyzedText) {
          developer.log('stopListening에서 최종 텍스트 분석: $_recognizedText',
              name: 'Speech');
          _lastAnalyzedText = _recognizedText;
          _analyzeRecognizedText();
        }

        // 상태 업데이트는 항상 수행
        _isListening = false;
        onListeningStateChanged(false);
        _timeoutOccurred = false;
      }
    }
  }

  void _analyzeRecognizedText() {
    // 이미 분석된 텍스트인지 확인
    if (_recognizedText.isEmpty) {
      developer.log('인식된 텍스트가 없습니다', name: 'Speech');
      onKeywordsDetected([]);
      return;
    }

    developer.log('텍스트 분석 시작: $_recognizedText', name: 'Speech');
    final String text = _recognizedText.toLowerCase();

    // 감지된 키워드 목록
    List<RecordType> detectedTypes = [];

    // "hurt"도 "heart"로 처리하도록 키워드 매칭 개선
    if (_checkKeyword(text, ['1', 'heart', 'hurt', '하트', '혈압', '혈압 측정'])) {
      developer.log('혈압 키워드 감지 (heart/hurt/혈압)', name: 'Speech');
      detectedTypes.add(RecordType.bloodPressure);
    }

    if (_checkKeyword(
        text, ['2', 'sugar', 'glucose', '슈가', '혈당', '당뇨', '혈당 측정'])) {
      developer.log('혈당 키워드 감지', name: 'Speech');
      detectedTypes.add(RecordType.bloodSugar);
    }

    if (_checkKeyword(text, ['3', 'weight', '웨이트', '체중', '몸무게', '체중 측정'])) {
      developer.log('체중 키워드 감지', name: 'Speech');
      detectedTypes.add(RecordType.weight);
    }

    if (_checkKeyword(text, ['4', 'waist', '웨이스트', '허리', '허리둘레', '허리 측정'])) {
      developer.log('허리둘레 키워드 감지', name: 'Speech');
      detectedTypes.add(RecordType.waistCircumference);
    }

    if (_checkKeyword(text, ['5', '히스토리', '기록', '이력'])) {
      developer.log('히스토리 키워드 감지', name: 'Speech');
      detectedTypes.add(RecordType.history);
    }

    // 감지된 전체 키워드 요약
    developer.log(
        '최종 감지된 키워드: ${detectedTypes.map((t) => t.toString()).join(', ')}',
        name: 'Speech');

    // 감지된 키워드 알림
    onKeywordsDetected(detectedTypes);
  }

  // 키워드 확인 헬퍼 함수 - 더 정교한 검사 추가
  bool _checkKeyword(String text, List<String> keywords) {
    for (var keyword in keywords) {
      // 완전일치 또는 단어의 일부로 포함된 경우
      if (text.contains(keyword)) {
        developer.log('키워드 "$keyword" 감지됨', name: 'Speech');
        return true;
      }

      // 'hurt'와 'heart' 같이 발음이 비슷한 단어들의 유사성 검사 (필요시 확장)
      if (keyword == 'heart' && text.contains('hurt')) {
        developer.log('유사 키워드 "hurt"가 "heart"로 감지됨', name: 'Speech');
        return true;
      }
      if (keyword == 'hurt' && text.contains('heart')) {
        developer.log('유사 키워드 "heart"가 "hurt"로 감지됨', name: 'Speech');
        return true;
      }
    }
    return false;
  }
}
