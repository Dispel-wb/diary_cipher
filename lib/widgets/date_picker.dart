import 'package:flutter/material.dart';

class DatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateChanged;

  const DatePicker({required this.initialDate, required this.onDateChanged, super.key});

  @override
  State<DatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<DatePicker> {
  late FixedExtentScrollController yearCtrl;
  late FixedExtentScrollController monthCtrl;
  late FixedExtentScrollController dayCtrl;
  late int selectedYear, selectedMonth, selectedDay;

  final List<int> years = List.generate(9000, (i) => 1000 + i);
  final List<int> months = List.generate(12, (i) => i + 1);

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
    selectedDay = widget.initialDate.day;
    yearCtrl = FixedExtentScrollController(initialItem: selectedYear - 1000);
    monthCtrl = FixedExtentScrollController(initialItem: selectedMonth - 1);
    // 初始化 dayCtrl，不通过 _updateDayController（避免 dispose 未初始化对象）
    final maxDay = _daysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDay) selectedDay = maxDay;
    dayCtrl = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  int _daysInMonth(int year, int month) {
    if (month == 2) {
      return (year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)) ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  void _updateDayController() {
    // 先释放旧的控制器，避免内存泄漏
    dayCtrl.dispose();
    final maxDay = _daysInMonth(selectedYear, selectedMonth);
    if (selectedDay > maxDay) selectedDay = maxDay;
    dayCtrl = FixedExtentScrollController(initialItem: selectedDay - 1);
  }

  void _emit() {
    widget.onDateChanged(DateTime(selectedYear, selectedMonth, selectedDay));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _wheel(
            controller: yearCtrl,
            items: years.map((y) => y.toString()).toList(),
            onChanged: (idx) {
              setState(() {
                selectedYear = years[idx];
                _updateDayController();
              });
              _emit();
            },
          ),
          const Text('年', style: TextStyle(fontSize: 18)),
          _wheel(
            controller: monthCtrl,
            items: months.map((m) => m.toString().padLeft(2, '0')).toList(),
            onChanged: (idx) {
              setState(() {
                selectedMonth = months[idx];
                _updateDayController();
              });
              _emit();
            },
          ),
          const Text('月', style: TextStyle(fontSize: 18)),
          _wheel(
            controller: dayCtrl,
            items: List.generate(
              _daysInMonth(selectedYear, selectedMonth),
              (d) => (d + 1).toString().padLeft(2, '0'),
            ),
            onChanged: (idx) {
              setState(() => selectedDay = idx + 1);
              _emit();
            },
          ),
          const Text('日', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 40,
        diameterRatio: 2.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) => Center(
            child: Text(items[index], style: const TextStyle(fontSize: 20)),
          ),
          childCount: items.length,
        ),
      ),
    );
  }

  @override
  void dispose() {
    yearCtrl.dispose();
    monthCtrl.dispose();
    dayCtrl.dispose();
    super.dispose();
  }
}