import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/database/database_helper.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/utils/speech_recognition_service.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late SpeechRecognitionService _speechService;
  String _recognizedText = '';
  bool _isListening = false;
  List<HealthRecord> _todayRecords = [];
  bool _isLoadingRecords = true;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    print('🏠 홈 화면 초기화');
    _speechService = SpeechRecognitionService(
      context: context,
      onTextRecognized: (text) {
        setState(() {
          _recognizedText = text;
        });
      },
      onRecordTypeDetected: (type) {
        setState(() {
          // 인식된 건강 기록 유형에 따른 추가 UI 로직
        });
      },
    );

    // 오늘의 기록 로드
    _loadTodayRecords();
  }

  void _startListening() async {
    print('🎤 음성 인식 시작');
    setState(() {
      _isListening = true;
      _recognizedText = '듣는 중...';
    });
    await _speechService.startListening();
  }

  void _stopListening() {
    print('🎤 음성 인식 중지');
    _speechService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  void dispose() {
    print('🏠 홈 화면 종료');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text(
          '건강 기록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 오늘의 요약 정보 카드
                Card(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '오늘의 건강',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            DateFormat('yyyy년 MM월 dd일').format(DateTime.now()),
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // 오늘의 요약 데이터 표시 (최근 기록들)
                      _buildRecentRecordSummary(),
                    ],
                  ),
                ),

                // 음성 인식 결과
                if (_recognizedText.isNotEmpty && _recognizedText != '듣는 중...')
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mic,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '인식된 음성',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _recognizedText,
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),

                // 건강 기록 유형 섹션
                Text(
                  '기록하기',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 16),

                // 기록 유형 카드 그리드
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildHealthRecordCard(
                      RecordType.bloodPressure,
                      Icons.favorite,
                      const Color(0xFFE57373),
                    ),
                    _buildHealthRecordCard(
                      RecordType.bloodSugar,
                      Icons.water_drop,
                      const Color(0xFF64B5F6),
                    ),
                    _buildHealthRecordCard(
                      RecordType.weight,
                      Icons.monitor_weight,
                      const Color(0xFF81C784),
                    ),
                    _buildHealthRecordCard(
                      RecordType.waistCircumference,
                      Icons.straighten,
                      const Color(0xFFFFB74D),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 기록 이력 버튼
                ElevatedButton.icon(
                  onPressed: () {
                    print('📋 이력 버튼 클릭');
                    context.push('/history');
                  },
                  icon: const Icon(Icons.history),
                  label: const Text(
                    '전체 기록 이력',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        tooltip: _isListening ? '음성 인식 중지' : '음성으로 기록하기',
        backgroundColor:
            _isListening ? Colors.red.shade400 : colorScheme.primary,
        child: Icon(
          _isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildRecentRecordSummary() {
    // 데이터 로딩 여부를 추적하는 상태 변수 추가 필요
    if (_isLoadingRecords) {
      return const Center(
        child: SizedBox(
          height: 40,
          width: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    // 최근 기록이 없는 경우
    if (_todayRecords.isEmpty) {
      return const Text(
        '아직 오늘의 기록이 없습니다',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }

    // 최근 기록이 있는 경우 - 기록 데이터 표시
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var type in RecordType.values)
          if (_getLatestRecordByType(type) != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _getColorForType(type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          _getIconForType(type),
                          size: 18,
                          color: _getColorForType(type),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        HealthRecord.getTypeName(type),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Text(
                    _getLatestRecordByType(type)!.getSummary(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getColorForType(type),
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '마지막 업데이트: ${_getLastUpdateTime()}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 아래 필요한 보조 메서드들도 추가해야 합니다

  // 타입별 색상 반환
  Color _getColorForType(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return const Color(0xFFE57373);
      case RecordType.bloodSugar:
        return const Color(0xFF64B5F6);
      case RecordType.weight:
        return const Color(0xFF81C784);
      case RecordType.waistCircumference:
        return const Color(0xFFFFB74D);
    }
  }

  // 타입별 아이콘 반환
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
    }
  }

  // 특정 타입의 최신 기록 반환
  HealthRecord? _getLatestRecordByType(RecordType type) {
    final records = _todayRecords.where((r) => r.type == type).toList();
    if (records.isEmpty) return null;

    // 날짜 내림차순 정렬
    records.sort((a, b) => b.date.compareTo(a.date));
    return records.first;
  }

  // 마지막 업데이트 시간 포맷팅
  String _getLastUpdateTime() {
    if (_todayRecords.isEmpty) return '-';

    // 가장 최근 기록 찾기
    final latestRecord =
        _todayRecords.reduce((a, b) => a.date.isAfter(b.date) ? a : b);

    return DateFormat('a h:mm', 'ko').format(latestRecord.date);
  }

  Widget _buildHealthRecordCard(RecordType type, IconData icon, Color color) {
    return InkWell(
      onTap: () => context.push('/record/${type.index}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              HealthRecord.getTypeName(type),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 오늘의 기록을 로드하는 메서드
  Future<void> _loadTodayRecords() async {
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      // 모든 기록 가져오기
      final allRecords = await _dbHelper.getAllHealthRecords();

      // 오늘 날짜 설정
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      // 오늘 기록만 필터링
      final todayRecords = allRecords.where((record) {
        return record.date.isAfter(startOfDay) &&
            record.date.isBefore(endOfDay);
      }).toList();

      if (mounted) {
        setState(() {
          _todayRecords = todayRecords;
          _isLoadingRecords = false;
        });
      }
    } catch (e) {
      print('오늘의 기록 로드 중 오류 발생: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }
  }

  // 다른 화면에서 돌아올 때 데이터 새로고침
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 포커스를 얻을 때마다 데이터 새로고침
    _loadTodayRecords();
  }
}
