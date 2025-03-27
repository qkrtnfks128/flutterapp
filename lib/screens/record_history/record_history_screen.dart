import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

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

    _loadRecords();
  }

  Future<void> _loadRecords() async {
    try {
      final allRecords = await _dbHelper.getAllHealthRecords();

      // 모든 기록을 가져온 후 타입별로 분류
      final bloodPressure =
          await _dbHelper.getHealthRecordsByType(RecordType.bloodPressure);
      final bloodSugar =
          await _dbHelper.getHealthRecordsByType(RecordType.bloodSugar);
      final weight = await _dbHelper.getHealthRecordsByType(RecordType.weight);
      final waist =
          await _dbHelper.getHealthRecordsByType(RecordType.waistCircumference);

      if (mounted) {
        setState(() {
          _allRecords = allRecords;
          _recordsByType = [bloodPressure, bloodSugar, weight, waist];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading records: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteRecord(HealthRecord record) async {
    await _dbHelper.deleteHealthRecord(record.id!);
    _loadRecords();
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
          tabs: const [
            Tab(text: '전체'),
            Tab(text: '혈압'),
            Tab(text: '혈당'),
            Tab(text: '체중'),
            Tab(text: '허리'),
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

    // 날짜별로 그룹화
    final groupedRecords = <String, List<HealthRecord>>{};
    for (final record in records) {
      final dateKey = DateFormat('yyyy-MM-dd').format(record.date);
      if (!groupedRecords.containsKey(dateKey)) {
        groupedRecords[dateKey] = [];
      }
      groupedRecords[dateKey]!.add(record);
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayRecords = groupedRecords[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                _formatDateHeader(dateKey),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            ...dayRecords.map((record) => _buildRecordCard(record)).toList(),
            const SizedBox(height: 8),
            if (index < sortedDates.length - 1) const Divider(),
          ],
        );
      },
    );
  }

  String _formatDateHeader(String dateKey) {
    final now = DateTime.now();
    final today = DateFormat('yyyy-MM-dd').format(now);
    final yesterday =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    if (dateKey == today) {
      return '오늘';
    } else if (dateKey == yesterday) {
      return '어제';
    } else {
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
    }
  }
}
