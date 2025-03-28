import 'dart:async';

import 'package:flutter/material.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/utils/speech_recognition_service.dart';
import 'package:go_router/go_router.dart';

class SpeechRecognitionWidget extends StatefulWidget {
  const SpeechRecognitionWidget({Key? key}) : super(key: key);

  @override
  State<SpeechRecognitionWidget> createState() =>
      _SpeechRecognitionWidgetState();
}

class _SpeechRecognitionWidgetState extends State<SpeechRecognitionWidget>
    with SingleTickerProviderStateMixin {
  bool _isListening = false;
  bool _isExpanded = false;
  String _recognizedText = '';
  List<RecordType> _detectedKeywords = [];
  late SpeechRecognitionService _speechService;

  // 로딩 애니메이션을 위한 컨트롤러
  late AnimationController _animationController;

  // 확장/축소 애니메이션
  late Animation<double> _expandAnimation;

  // 20초 타이머
  Timer? _autoCollapseTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _speechService = SpeechRecognitionService(
      context: context,
      onTextRecognized: (text) {
        setState(() {
          _recognizedText = text;
        });
      },
      onRecordTypeDetected: (type) {
        // 자동 네비게이션은 비활성화
      },
      onListeningStateChanged: (isListening) {
        setState(() {
          _isListening = isListening;
          if (isListening) {
            _isExpanded = true;
            _animationController.forward();
          } else {
            _resetCollapseTimer();
          }
        });
      },
      onKeywordsDetected: (keywords) {
        setState(() {
          _detectedKeywords = keywords;
        });
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoCollapseTimer?.cancel();
    super.dispose();
  }

  // 자동 축소 타이머 설정
  void _resetCollapseTimer() {
    _autoCollapseTimer?.cancel();
    _autoCollapseTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && !_isListening) {
        setState(() {
          _isExpanded = false;
        });
        _animationController.reverse();
      }
    });
  }

  // 음성 인식 시작
  void _startListening() {
    setState(() {
      _recognizedText = '';
      _detectedKeywords = [];
      _isExpanded = true;
    });
    _animationController.forward();
    _speechService.startListening();
  }

  // 음성 인식 중지
  void _stopListening() {
    _speechService.stopListening();
    _resetCollapseTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.bottomRight,
      child: AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          return Container(
            width: _isExpanded ? MediaQuery.of(context).size.width * 0.9 : 56,
            height: _isExpanded ? null : 56,
            constraints: BoxConstraints(
              maxHeight: _isExpanded ? 300 : 56,
              minHeight: 56,
            ),
            margin: const EdgeInsets.only(bottom: 16.0, right: 16.0),
            decoration: BoxDecoration(
              color: _isListening
                  ? Colors.red.withOpacity(0.9)
                  : colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: _isExpanded
                  ? _buildExpandedContent()
                  : _buildCollapsedContent(),
            ),
          );
        },
      ),
    );
  }

  // 접힌 상태 (마이크 아이콘만)
  Widget _buildCollapsedContent() {
    return InkWell(
      onTap: _startListening,
      borderRadius: BorderRadius.circular(28),
      child: const Center(
        child: Icon(
          Icons.mic,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  // 펼쳐진 상태
  Widget _buildExpandedContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더 (마이크 아이콘 + 타이틀 + 닫기 버튼)
            Row(
              children: [
                Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  _isListening ? '음성 인식 중...' : '음성 인식 결과',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 액션 버튼 (듣기 중지 또는 닫기)
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.stop : Icons.close,
                    color: Colors.white,
                  ),
                  onPressed: _isListening
                      ? _stopListening
                      : () {
                          setState(() {
                            _isExpanded = false;
                          });
                          _animationController.reverse();
                        },
                ),
              ],
            ),

            // 듣는 중 애니메이션
            if (_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    const Text(
                      '음성을 듣고 있어요',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getLoadingDots(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

            // 인식된 텍스트 표시
            if (_recognizedText.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '인식된 내용:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _recognizedText,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // 키워드 버튼 표시
            if (_detectedKeywords.isNotEmpty && !_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '아래 중 하려는 기록을 선택하세요',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ..._detectedKeywords.map((type) => ActionChip(
                              backgroundColor: Colors.white,
                              avatar: CircleAvatar(
                                backgroundColor: _getColorForType(type),
                                child: Icon(
                                  _getIconForType(type),
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                              label: Text(_getLabelForType(type)),
                              onPressed: () {
                                context.go('/record/${type.index}');
                              },
                            )),
                        if (_recognizedText.toLowerCase().contains('기록') ||
                            _recognizedText.toLowerCase().contains('이력') ||
                            _recognizedText.toLowerCase().contains('히스토리'))
                          ActionChip(
                            backgroundColor: Colors.white,
                            avatar: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.history,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            label: const Text('기록 확인'),
                            onPressed: () {
                              context.go('/history');
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              )
            else if (_recognizedText.isNotEmpty && !_isListening)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '인식된 건강 데이터 키워드가 없습니다.',
                  style: TextStyle(
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 로딩 애니메이션 점(...)을 표시하는 함수
  String _getLoadingDots() {
    final int dotsCount =
        (DateTime.now().millisecondsSinceEpoch / 300).floor() % 4;
    return '.' * dotsCount;
  }

  // 건강 기록 타입에 따른 아이콘 반환
  IconData _getIconForType(RecordType type) {
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
        return Icons.error;
    }
  }

  // 건강 기록 타입에 따른 색상 반환
  Color _getColorForType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return Colors.red;
      case RecordType.bloodSugar:
        return Colors.orange;
      case RecordType.weight:
        return Colors.green;
      case RecordType.waistCircumference:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // 건강 기록 타입에 따른 라벨 반환
  String _getLabelForType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return '혈압 측정';
      case RecordType.bloodSugar:
        return '혈당 측정';
      case RecordType.weight:
        return '체중 측정';
      case RecordType.waistCircumference:
        return '허리둘레 측정';
      default:
        return '알 수 없음';
    }
  }
}
