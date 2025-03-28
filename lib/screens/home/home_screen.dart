import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/controllers/home_controller.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/utils/speech_recognition_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late HomeController _controller;
  late SpeechRecognitionService _speechService;
  bool _isListening = false;
  List<RecordType> _detectedKeywords = [];
  String _recognizedText = '';
  bool _showRecognitionResult = false;
  Timer? _resultTimer;

  // 음성 인식 결과창 닫기 메서드
  void _clearRecognitionResult() {
    setState(() {
      _showRecognitionResult = false;
      _recognizedText = '';
      _detectedKeywords = [];
      _resultTimer?.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = HomeController();

    _speechService = SpeechRecognitionService(
      context: context,
      onTextRecognized: (text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
        }
      },
      onRecordTypeDetected: _navigateToRecordScreen,
      onListeningStateChanged: (isListening) {
        if (mounted) {
          setState(() {
            _isListening = isListening;

            if (!isListening && _recognizedText.isNotEmpty) {
              _showRecognitionResult = true;

              _resultTimer?.cancel();

              _resultTimer = Timer(const Duration(seconds: 10), () {
                if (mounted) {
                  _clearRecognitionResult();
                }
              });
            }
          });
        }
      },
      onKeywordsDetected: (keywords) {
        if (mounted) {
          setState(() {
            _detectedKeywords = keywords;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _resultTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.loadTodayRecords();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.loadTodayRecords();
  }

  void _navigateToRecordScreen(RecordType type) {
    _clearRecognitionResult(); // 화면 이동 전 결과창 닫기
    context.push('/record/${type.index}');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider.value(
      value: _controller,
      child: Scaffold(
        backgroundColor: Color(0xFFF7F8FC), // 밝은 배경색
        appBar: _buildAppBar(),
        body: Consumer<HomeController>(
          builder: (context, controller, _) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(context, controller),
                    const SizedBox(height: 24),
                    _buildRecordTypesList(context),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '오늘의 건강 기록',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/history'),
                          child: Text(
                            '전체보기',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRecentRecordsList(context, controller),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: _buildFabWithSpeechUI(),
      ),
    );
  }

  // 상단 요약 카드
  Widget _buildSummaryCard(BuildContext context, HomeController controller) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRecordsToday = controller.todayRecords.length;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '건강 기록 요약',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '오늘',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '$totalRecordsToday건',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              controller.isLoadingRecords ? '로딩 중...' : '오늘 기록된 건강 데이터',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 16),
            Divider(color: Colors.white.withOpacity(0.2), height: 1),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRecordTypeSummary(
                  context,
                  RecordType.bloodPressure,
                  controller,
                  Icons.favorite,
                ),
                _buildRecordTypeSummary(
                  context,
                  RecordType.bloodSugar,
                  controller,
                  Icons.water_drop,
                ),
                _buildRecordTypeSummary(
                  context,
                  RecordType.weight,
                  controller,
                  Icons.monitor_weight,
                ),
                _buildRecordTypeSummary(
                  context,
                  RecordType.waistCircumference,
                  controller,
                  Icons.straighten,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 요약 카드 내 각 기록 타입별 요약
  Widget _buildRecordTypeSummary(BuildContext context, RecordType type,
      HomeController controller, IconData icon) {
    final record = controller.getLatestRecordByType(type);
    final count = controller.todayRecords.where((r) => r.type == type).length;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        SizedBox(height: 8),
        Text(
          '$count건',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          _getShortRecordTypeText(type),
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // 건강 기록 유형 아이콘 목록
  Widget _buildRecordTypesList(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildRecordTypeIcon(
            context,
            RecordType.bloodPressure,
            Icons.favorite,
            Colors.red,
          ),
          _buildRecordTypeIcon(
            context,
            RecordType.bloodSugar,
            Icons.water_drop,
            Colors.purple,
          ),
          _buildRecordTypeIcon(
            context,
            RecordType.weight,
            Icons.monitor_weight,
            Colors.blue,
          ),
          _buildRecordTypeIcon(
            context,
            RecordType.waistCircumference,
            Icons.straighten,
            Colors.green,
          ),
        ],
      ),
    );
  }

  // 각 건강 기록 유형 아이콘
  Widget _buildRecordTypeIcon(
      BuildContext context, RecordType type, IconData icon, Color color) {
    return InkWell(
      onTap: () => context.push('/record/${type.index}'),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _getRecordTypeText(type),
            style: TextStyle(
              color: Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 최근 기록 목록
  Widget _buildRecentRecordsList(
      BuildContext context, HomeController controller) {
    if (controller.isLoadingRecords) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (controller.todayRecords.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                '오늘 등록된 건강 기록이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                child: Text('새 기록 추가하기'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildRecordSummaryItem(context, RecordType.bloodPressure, controller),
        _buildRecordSummaryItem(context, RecordType.bloodSugar, controller),
        _buildRecordSummaryItem(context, RecordType.weight, controller),
        _buildRecordSummaryItem(
            context, RecordType.waistCircumference, controller),
      ],
    );
  }

  // 각 기록 항목 카드
  Widget _buildRecordSummaryItem(
      BuildContext context, RecordType type, HomeController controller) {
    final record = controller.getLatestRecordByType(type);
    if (record == null) return const SizedBox.shrink();

    final color = controller.getColorForRecordType(type);
    final icon = controller.getIconForRecordType(type);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRecordTypeText(type),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    controller.getFormattedValue(record),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                //   decoration: BoxDecoration(
                //     color: color.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Icon(Icons.trending_up, size: 14, color: color),
                //       SizedBox(width: 4),
                //       Text(
                //         '정상',
                //         style: TextStyle(
                //           fontSize: 12,
                //           color: color,
                //           fontWeight: FontWeight.bold,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // SizedBox(height: 8),
                Text(
                  controller.formatLastUpdateTime(
                    DateTime.fromMillisecondsSinceEpoch(
                        record.date.millisecondsSinceEpoch),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // FAB와 음성 인식 UI를 함께 구성하는 위젯
  Widget _buildFabWithSpeechUI() {
    return Stack(
      children: [
        // 음성 인식 결과 표시 (FAB 위에 위치)
        if (_isListening || _showRecognitionResult)
          Positioned(
            bottom: 80, // FAB 위에 위치
            right: 0,
            left: 0, // 왼쪽 끝까지 확장
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), // 좌우 패딩 추가
              child: Container(
                width: double.infinity, // 가로 전체 채우기
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isListening ? Icons.mic : Icons.mic_off,
                                  color: _isListening
                                      ? Colors.redAccent
                                      : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isListening ? '음성 인식 중...' : '인식 결과',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _isListening
                                        ? Colors.redAccent
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            if (!_isListening)
                              InkWell(
                                onTap: _clearRecognitionResult,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_recognizedText.isNotEmpty || _isListening) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isListening
                                    ? Colors.redAccent.withOpacity(0.3)
                                    : Colors.grey.shade300,
                              ),
                            ),
                            width: double.infinity,
                            child: Text(
                              _recognizedText.isEmpty && _isListening
                                  ? '말씀해 주세요...'
                                  : '인식된 텍스트: $_recognizedText',
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: _isListening
                                    ? Colors.black87
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                        if (_detectedKeywords.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _detectedKeywords.map((type) {
                              final color =
                                  _controller.getColorForRecordType(type);

                              return GestureDetector(
                                onTap: () {
                                  _clearRecognitionResult(); // 키워드 탭 시 결과창 닫기
                                  if (type == RecordType.history) {
                                    context.push('/history');
                                  } else {
                                    context.push('/record/${type.index}');
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: color.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _controller.getIconForRecordType(type),
                                        size: 16,
                                        color: color,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _getRecordTypeText2(type),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                        if (_detectedKeywords.isEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            '음성 인식 결과가 없습니다.',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // FAB 버튼
        Positioned(
          bottom: 0,
          right: 0,
          child: FloatingActionButton(
            onPressed: () {
              if (_isListening) {
                _speechService.stopListening();
              } else {
                _clearRecognitionResult(); // 음성 인식 시작 전 초기화
                _speechService.startListening();
              }
            },
            child: Icon(_isListening ? Icons.mic : Icons.mic_none),
            tooltip: '음성으로 건강 기록하기',
            backgroundColor: _isListening ? Colors.redAccent : null,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  // 간략한 기록 타입 텍스트
  String _getShortRecordTypeText(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return '혈압';
      case RecordType.bloodSugar:
        return '혈당';
      case RecordType.weight:
        return '체중';
      case RecordType.waistCircumference:
        return '허리';
      case RecordType.history:
        return '기록';
    }
  }

  String _getRecordTypeText(RecordType type) {
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

  String _getRecordTypeText2(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return '혈압 기록';
      case RecordType.bloodSugar:
        return '혈당 기록';
      case RecordType.weight:
        return '체중 기록';
      case RecordType.waistCircumference:
        return '허리둘레 기록';
      case RecordType.history:
        return '건강 기록 이력';
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        '망키의 건강 기록',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history, color: Colors.black),
          onPressed: () {
            context.push('/history');
          },
        ),
        IconButton(
          icon: const Icon(Icons.show_chart, color: Colors.black),
          onPressed: () {
            context.push('/trends');
          },
        ),
      ],
    );
  }
}
