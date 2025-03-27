import 'package:flutter/material.dart';
import 'package:healthapp/models/health_record.dart';
import 'package:healthapp/database/database_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class HealthRecordScreen extends StatefulWidget {
  final RecordType recordType;

  const HealthRecordScreen({
    super.key,
    required this.recordType,
  });

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  DateTime _selectedDate = DateTime.now();
  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    switch (widget.recordType) {
      case RecordType.bloodPressure:
        _controllers['systolic'] = TextEditingController();
        _controllers['diastolic'] = TextEditingController();
        _controllers['pulse'] = TextEditingController();
        break;
      case RecordType.bloodSugar:
        _controllers['value'] = TextEditingController();
        _controllers['memo'] = TextEditingController();
        break;
      case RecordType.weight:
        _controllers['value'] = TextEditingController();
        break;
      case RecordType.waistCircumference:
        _controllers['value'] = TextEditingController();
        break;
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final values = <String, dynamic>{};
    _controllers.forEach((key, controller) {
      values[key] = controller.text;
    });

    final record = HealthRecord(
      type: widget.recordType,
      date: _selectedDate,
      recordValues: values,
    );

    await _dbHelper.insertHealthRecord(record);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건강 정보가 저장되었습니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconForRecordType(),
              color: _getColorForRecordType(),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '${HealthRecord.getTypeName(widget.recordType)} 기록',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 및 시간 선택 위젯
                _buildDateTimeSelector(),

                const SizedBox(height: 24),

                // 입력 폼
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '측정 정보',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 입력 필드들
                      ..._buildFormInputs(),

                      const SizedBox(height: 32),

                      // 저장 버튼
                      ElevatedButton(
                        onPressed: _saveRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getColorForRecordType(),
                          foregroundColor: Colors.white,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              '저장하기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector() {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '날짜 및 시간',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: _getColorForRecordType(),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    ).then((selectedDate) {
                      if (selectedDate != null) {
                        setState(() {
                          _selectedDate = selectedDate;
                        });
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('yyyy-MM-dd').format(DateTime.now()),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    // 시간 선택 다이얼로그 표시
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(DateTime.now()),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.access_time, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFormInputs() {
    switch (widget.recordType) {
      case RecordType.bloodPressure:
        return [
          _buildInputField('수축기 혈압', '수축기 혈압을 입력하세요 (mmHg)', 'systolic'),
          _buildInputField('이완기 혈압', '이완기 혈압을 입력하세요 (mmHg)', 'diastolic'),
          _buildInputField('맥박', '맥박을 입력하세요 (회/분)', 'pulse', isRequired: false),
        ];
      case RecordType.bloodSugar:
        return [
          _buildInputField('혈당', '혈당 수치를 입력하세요 (mg/dL)', 'value'),
          _buildInputField('메모', '식사 전/후 등 메모를 입력하세요', 'memo',
              isRequired: false),
        ];
      case RecordType.weight:
        return [
          _buildInputField('체중', '체중을 입력하세요 (kg)', 'value'),
        ];
      case RecordType.waistCircumference:
        return [
          _buildInputField('허리둘레', '허리둘레를 입력하세요 (cm)', 'value'),
        ];
    }
  }

  Widget _buildInputField(String label, String hint, String controllerKey,
      {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
          ),
          TextFormField(
            controller: _controllers[controllerKey],
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: controllerKey == 'value' ||
                      controllerKey == 'systolic' ||
                      controllerKey == 'diastolic'
                  ? Icon(
                      Icons.monitor_heart_outlined,
                      color: _getColorForRecordType().withOpacity(0.7),
                    )
                  : null,
            ),
            keyboardType: TextInputType.number,
            validator: isRequired
                ? (value) {
                    if (value == null || value.isEmpty) {
                      return '값을 입력해주세요';
                    }
                    return null;
                  }
                : null,
          ),
        ],
      ),
    );
  }

  IconData _getIconForRecordType() {
    switch (widget.recordType) {
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

  Color _getColorForRecordType() {
    switch (widget.recordType) {
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
