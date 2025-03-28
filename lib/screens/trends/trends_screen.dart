import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:healthapp/database/database_helper.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:intl/intl.dart';

class TrendsScreen extends StatefulWidget {
  final RecordType? initialType;

  const TrendsScreen({Key? key, this.initialType}) : super(key: key);

  @override
  _TrendsScreenState createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 날짜 범위 관련 변수
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedPeriod = '1주일';
  final List<String> _periodOptions = ['1주일', '1개월', '3개월', '6개월', '1년'];

  // 각 타입별 건강 기록 데이터
  List<HealthRecord> _bloodPressureRecords = [];
  List<HealthRecord> _bloodSugarRecords = [];
  List<HealthRecord> _weightRecords = [];
  List<HealthRecord> _waistRecords = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 4,
        vsync: this,
        initialIndex:
            widget.initialType != null ? widget.initialType!.index : 0);

    // 초기 날짜 범위 설정 (기본 1주일)
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 7));

    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 기간 변경 시 호출되는 함수
  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      _endDate = DateTime.now();

      switch (period) {
        case '1주일':
          _startDate = _endDate.subtract(const Duration(days: 7));
          break;
        case '1개월':
          _startDate =
              DateTime(_endDate.year, _endDate.month - 1, _endDate.day);
          break;
        case '3개월':
          _startDate =
              DateTime(_endDate.year, _endDate.month - 3, _endDate.day);
          break;
        case '6개월':
          _startDate =
              DateTime(_endDate.year, _endDate.month - 6, _endDate.day);
          break;
        case '1년':
          _startDate =
              DateTime(_endDate.year - 1, _endDate.month, _endDate.day);
          break;
      }

      _loadRecords();
    });
  }

  // 기록 데이터 로드
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);

    try {
      _bloodPressureRecords =
          await _dbHelper.getHealthRecordsByTypeAndDateRange(
              RecordType.bloodPressure,
              _startDate.millisecondsSinceEpoch,
              _endDate.millisecondsSinceEpoch);

      _bloodSugarRecords = await _dbHelper.getHealthRecordsByTypeAndDateRange(
          RecordType.bloodSugar,
          _startDate.millisecondsSinceEpoch,
          _endDate.millisecondsSinceEpoch);

      _weightRecords = await _dbHelper.getHealthRecordsByTypeAndDateRange(
          RecordType.weight,
          _startDate.millisecondsSinceEpoch,
          _endDate.millisecondsSinceEpoch);

      _waistRecords = await _dbHelper.getHealthRecordsByTypeAndDateRange(
          RecordType.waistCircumference,
          _startDate.millisecondsSinceEpoch,
          _endDate.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('데이터 로드 중 오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '건강 데이터 추세',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodSelector(),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              isScrollable: false,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorSize: TabBarIndicatorSize.tab,
              indicator: BoxDecoration(
                color: _getTabColor(_tabController.index),
              ),
              tabs: const [
                Tab(text: '혈압'),
                Tab(text: '혈당'),
                Tab(text: '체중'),
                Tab(text: '허리둘레'),
              ],
              onTap: (index) {
                setState(() {});
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBloodPressureTab(),
                        _buildBloodSugarTab(),
                        _buildWeightTab(),
                        _buildWaistTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 기간 선택 위젯
  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _periodOptions.map((period) {
          bool isSelected = period == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              selectedColor:
                  _getTabColor(_tabController.index).withOpacity(0.8),
              onSelected: (selected) {
                if (selected) _changePeriod(period);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // 탭 색상 가져오기
  Color _getTabColor(int index) {
    final RecordType type = RecordType.values[index];
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

  // 빈 데이터 표시
  Widget _buildEmptyDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '선택한 기간에 데이터가 없습니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '다른 기간을 선택하거나 새로운 기록을 추가해보세요',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 통계 요약 카드
  Widget _buildStatisticsCard({
    required String title,
    required String value,
    required Color color,
    IconData? icon,
    String? unit,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, color: color, size: 20),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (unit != null)
                  Text(
                    ' $unit',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 혈압 탭 구성
  Widget _buildBloodPressureTab() {
    if (_bloodPressureRecords.isEmpty) {
      return _buildEmptyDataView();
    }

    // 수축기 혈압과 이완기 혈압 데이터 추출
    List<FlSpot> systolicSpots = [];
    List<FlSpot> diastolicSpots = [];

    // x축 간격 계산
    double interval = _bloodPressureRecords.length > 1 ? 1.0 : 0.5;

    for (int i = 0; i < _bloodPressureRecords.length; i++) {
      final record = _bloodPressureRecords[i];
      final systolic =
          double.tryParse(record.recordValues['systolic'] ?? '0') ?? 0;
      final diastolic =
          double.tryParse(record.recordValues['diastolic'] ?? '0') ?? 0;

      systolicSpots.add(FlSpot(i.toDouble(), systolic));
      diastolicSpots.add(FlSpot(i.toDouble(), diastolic));
    }

    // 평균 계산
    double avgSystolic = 0;
    double avgDiastolic = 0;
    int validCount = 0;

    for (final record in _bloodPressureRecords) {
      final systolic =
          double.tryParse(record.recordValues['systolic'] ?? '0') ?? 0;
      final diastolic =
          double.tryParse(record.recordValues['diastolic'] ?? '0') ?? 0;

      if (systolic > 0 && diastolic > 0) {
        avgSystolic += systolic;
        avgDiastolic += diastolic;
        validCount++;
      }
    }

    if (validCount > 0) {
      avgSystolic = avgSystolic / validCount;
      avgDiastolic = avgDiastolic / validCount;
    }

    // 최고, 최저 계산
    double maxSystolic = systolicSpots.isEmpty
        ? 0
        : systolicSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double minSystolic = systolicSpots.isEmpty
        ? 0
        : systolicSpots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        // 통계 카드
        Row(
          children: [
            Expanded(
              child: _buildStatisticsCard(
                title: '평균 수축기',
                value: avgSystolic.toStringAsFixed(1),
                color: Colors.red,
                icon: Icons.trending_up,
                unit: 'mmHg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticsCard(
                title: '평균 이완기',
                value: avgDiastolic.toStringAsFixed(1),
                color: Colors.blue,
                icon: Icons.trending_down,
                unit: 'mmHg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '혈압 추세',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 20,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 &&
                                  value < _bloodPressureRecords.length) {
                                final record =
                                    _bloodPressureRecords[value.toInt()];
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        record.date.millisecondsSinceEpoch);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      minX: -0.5,
                      maxX: _bloodPressureRecords.length - 0.5,
                      minY: (minSystolic * 0.9).floorToDouble(),
                      maxY: (maxSystolic * 1.1).ceilToDouble(),
                      lineBarsData: [
                        // 수축기 혈압 라인
                        LineChartBarData(
                          spots: systolicSpots,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.1),
                          ),
                        ),
                        // 이완기 혈압 라인
                        LineChartBarData(
                          spots: diastolicSpots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('수축기'),
                    const SizedBox(width: 16),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('이완기'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 혈당 탭 구성
  Widget _buildBloodSugarTab() {
    if (_bloodSugarRecords.isEmpty) {
      return _buildEmptyDataView();
    }

    List<FlSpot> spots = [];
    double interval = _bloodSugarRecords.length > 1 ? 1.0 : 0.5;

    for (int i = 0; i < _bloodSugarRecords.length; i++) {
      final record = _bloodSugarRecords[i];
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // 평균, 최대, 최소 계산
    double avg = 0;
    int validCount = 0;

    for (final record in _bloodSugarRecords) {
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      if (value > 0) {
        avg += value;
        validCount++;
      }
    }

    if (validCount > 0) {
      avg = avg / validCount;
    }

    double max = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double min = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticsCard(
                title: '평균 혈당',
                value: avg.toStringAsFixed(1),
                color: Colors.blue,
                icon: Icons.water_drop,
                unit: 'mg/dL',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticsCard(
                title: '최고 / 최저',
                value: '${max.toInt()} / ${min.toInt()}',
                color: Colors.blue,
                icon: Icons.compare_arrows,
                unit: 'mg/dL',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '혈당 추세',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 &&
                                  value < _bloodSugarRecords.length) {
                                final record =
                                    _bloodSugarRecords[value.toInt()];
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        record.date.millisecondsSinceEpoch);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      minX: -0.5,
                      maxX: _bloodSugarRecords.length - 0.5,
                      minY: (min * 0.9).floorToDouble(),
                      maxY: (max * 1.1).ceilToDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 체중 탭 구성
  Widget _buildWeightTab() {
    if (_weightRecords.isEmpty) {
      return _buildEmptyDataView();
    }

    List<FlSpot> spots = [];
    double interval = _weightRecords.length > 1 ? 1.0 : 0.5;

    for (int i = 0; i < _weightRecords.length; i++) {
      final record = _weightRecords[i];
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // 평균, 최대, 최소 계산
    double avg = 0;
    int validCount = 0;

    for (final record in _weightRecords) {
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      if (value > 0) {
        avg += value;
        validCount++;
      }
    }

    if (validCount > 0) {
      avg = avg / validCount;
    }

    double max = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double min = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticsCard(
                title: '평균 체중',
                value: avg.toStringAsFixed(1),
                color: Colors.green,
                icon: Icons.monitor_weight,
                unit: 'kg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticsCard(
                title: '최고 / 최저',
                value: '${max.toStringAsFixed(1)} / ${min.toStringAsFixed(1)}',
                color: Colors.green,
                icon: Icons.compare_arrows,
                unit: 'kg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '체중 추세',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < _weightRecords.length) {
                                final record = _weightRecords[value.toInt()];
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        record.date.millisecondsSinceEpoch);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      minX: -0.5,
                      maxX: _weightRecords.length - 0.5,
                      minY: (min * 0.95).floorToDouble(),
                      maxY: (max * 1.05).ceilToDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.green,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.green.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 허리둘레 탭 구성
  Widget _buildWaistTab() {
    if (_waistRecords.isEmpty) {
      return _buildEmptyDataView();
    }

    List<FlSpot> spots = [];
    double interval = _waistRecords.length > 1 ? 1.0 : 0.5;

    for (int i = 0; i < _waistRecords.length; i++) {
      final record = _waistRecords[i];
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      spots.add(FlSpot(i.toDouble(), value));
    }

    // 평균, 최대, 최소 계산
    double avg = 0;
    int validCount = 0;

    for (final record in _waistRecords) {
      final value = double.tryParse(record.recordValues['value'] ?? '0') ?? 0;
      if (value > 0) {
        avg += value;
        validCount++;
      }
    }

    if (validCount > 0) {
      avg = avg / validCount;
    }

    double max = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    double min = spots.isEmpty
        ? 0
        : spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatisticsCard(
                title: '평균 허리둘레',
                value: avg.toStringAsFixed(1),
                color: Colors.orange,
                icon: Icons.straighten,
                unit: 'cm',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatisticsCard(
                title: '최고 / 최저',
                value: '${max.toStringAsFixed(1)} / ${min.toStringAsFixed(1)}',
                color: Colors.orange,
                icon: Icons.compare_arrows,
                unit: 'cm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '허리둘레 추세',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: interval,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < _waistRecords.length) {
                                final record = _waistRecords[value.toInt()];
                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(
                                        record.date.millisecondsSinceEpoch);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${date.month}/${date.day}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                      ),
                      minX: -0.5,
                      maxX: _waistRecords.length - 0.5,
                      minY: (min * 0.95).floorToDouble(),
                      maxY: (max * 1.05).ceilToDouble(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.orange,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.orange.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
