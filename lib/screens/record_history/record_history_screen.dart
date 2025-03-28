import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:math' as math;

class RecordHistoryScreen extends StatefulWidget {
  const RecordHistoryScreen({super.key});

  @override
  State<RecordHistoryScreen> createState() => _RecordHistoryScreenState();
}

class _RecordHistoryScreenState extends State<RecordHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<HealthRecord> _allRecords = [];
  List<List<HealthRecord>> _recordsByType = [[], [], [], []];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // 한국어 로케일 초기화
    initializeDateFormatting('ko_KR', null).then((_) {
      _loadRecords();
    });
  }

  Future<void> _loadRecords() async {
    try {
      debugPrint('기록 로딩 시작');
      setState(() {
        _isLoading = true;
      });

      // 모든 기록 로드
      final allRecords = await _dbHelper.getAllHealthRecords();
      debugPrint('전체 기록 로드 완료: ${allRecords.length}개');

      // 타입별 기록 로드
      final bloodPressure =
          await _dbHelper.getHealthRecordsByType(RecordType.bloodPressure);
      debugPrint('혈압 기록 로드 완료: ${bloodPressure.length}개');

      final bloodSugar =
          await _dbHelper.getHealthRecordsByType(RecordType.bloodSugar);
      debugPrint('혈당 기록 로드 완료: ${bloodSugar.length}개');

      final weight = await _dbHelper.getHealthRecordsByType(RecordType.weight);
      debugPrint('체중 기록 로드 완료: ${weight.length}개');

      final waist =
          await _dbHelper.getHealthRecordsByType(RecordType.waistCircumference);
      debugPrint('허리둘레 기록 로드 완료: ${waist.length}개');

      if (mounted) {
        setState(() {
          _allRecords = allRecords;
          _recordsByType = [bloodPressure, bloodSugar, weight, waist];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('기록 로드 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // 오류 메시지 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '데이터 로드 중 오류가 발생했습니다: ${e.toString().substring(0, math.min(100, e.toString().length))}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    try {
      await _dbHelper.deleteHealthRecord(record.id!);
      debugPrint('기록 삭제 완료: ID ${record.id}');
      _loadRecords();
    } catch (e) {
      debugPrint('기록 삭제 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('기록 삭제 중 오류가 발생했습니다')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text(
          '건강 기록 이력',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          indicatorWeight: 3,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '혈압'),
            Tab(text: '혈당'),
            Tab(text: '체중'),
            Tab(text: '허리둘레'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecordList(_allRecords),
                _buildRecordList(_recordsByType[0]), // 혈압
                _buildRecordList(_recordsByType[1]), // 혈당
                _buildRecordList(_recordsByType[2]), // 체중
                _buildRecordList(_recordsByType[3]), // 허리둘레
              ],
            ),
    );
  }

  Widget _buildRecordList(List<HealthRecord> records) {
    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '기록이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // 데이터를 날짜별로 그룹화
    Map<String, List<HealthRecord>> groupedRecords =
        _groupRecordsByDate(records);

    // 날짜별로 내림차순 정렬 (최신 날짜가 먼저 표시)
    List<String> sortedKeys = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayRecords = groupedRecords[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _formatDateHeader(dateKey, context),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...dayRecords.map((record) => _buildRecordCard(record)).toList(),
            const SizedBox(height: 8),
            if (index < sortedKeys.length - 1) const Divider(),
          ],
        );
      },
    );
  }

  // 데이터를 날짜별로 그룹화
  Map<String, List<HealthRecord>> _groupRecordsByDate(
      List<HealthRecord> records) {
    final Map<String, List<HealthRecord>> grouped = {};

    for (var record in records) {
      // 날짜 키 생성 (yyyy-MM-dd 형태)
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);

      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(record);
    }

    // 날짜별로 내림차순 정렬 (최신 날짜가 먼저 표시)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return {
      for (var key in sortedKeys) key: grouped[key]!,
    };
  }

  // 날짜 섹션 헤더 포맷팅
  String _formatDateHeader(String dateKey, BuildContext context) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) {
      return '오늘';
    } else if (dateKey == yesterday) {
      return '어제';
    } else {
      // 날짜 포맷팅
      final date = DateFormat('yyyy-MM-dd').parse(dateKey);
      return DateFormat('yyyy년 MM월 dd일 (E)', 'ko').format(date);
    }
  }

  Widget _buildRecordCard(HealthRecord record) {
    Color cardColor;
    IconData cardIcon;

    switch (record.type) {
      case RecordType.bloodPressure:
        cardColor = const Color(0xFFE57373).withOpacity(0.12);
        cardIcon = Icons.favorite;
        break;
      case RecordType.bloodSugar:
        cardColor = const Color(0xFF64B5F6).withOpacity(0.12);
        cardIcon = Icons.water_drop;
        break;
      case RecordType.weight:
        cardColor = const Color(0xFF81C784).withOpacity(0.12);
        cardIcon = Icons.monitor_weight;
        break;
      case RecordType.waistCircumference:
        cardColor = const Color(0xFFFFB74D).withOpacity(0.12);
        cardIcon = Icons.straighten;
        break;
      case RecordType.history:
        cardColor = Colors.grey.shade100;
        cardIcon = Icons.history;
        break;
    }

    return Dismissible(
      key: Key(record.id.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('기록 삭제'),
              content: const Text('이 기록을 삭제하시겠습니까?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        _deleteRecord(record);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              cardIcon,
              color: _getIconColor(record.type),
            ),
          ),
          title: Text(
            HealthRecord.getTypeName(record.type),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            DateFormat('a h:mm', 'ko').format(record.date),
            style: TextStyle(color: Colors.grey.shade700),
          ),
          trailing: Text(
            record.getSummary(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }

  Color _getIconColor(RecordType type) {
    switch (type) {
      case RecordType.bloodPressure:
        return const Color(0xFFE57373);
      case RecordType.bloodSugar:
        return const Color(0xFF64B5F6);
      case RecordType.weight:
        return const Color(0xFF81C784);
      case RecordType.waistCircumference:
        return const Color(0xFFFFB74D);
      case RecordType.history:
        return Colors.grey.shade400;
    }
  }

  // 날짜 포맷팅 함수
  String _formatDate(DateTime date) {
    // 년월일 포맷팅 (한글 로케일 적용)
    return DateFormat('yyyy년 MM월 dd일', 'ko').format(date);
  }

  // 시간 포맷팅 함수
  String _formatTime(DateTime date) {
    // 오전/오후 시:분 포맷팅 (한글 로케일 적용)
    return DateFormat('a h:mm', 'ko').format(date);
  }

  // 날짜와 시간을 함께 포맷팅하는 함수
  String _formatDateTime(DateTime date) {
    // 년월일 오전/오후 시:분 포맷팅 (한글 로케일 적용)
    return DateFormat('yyyy년 MM월 dd일 a h:mm', 'ko').format(date);
  }
}
