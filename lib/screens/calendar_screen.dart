import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<Habit> _habits = [];
  bool _loading = true;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await HabitStorage.loadHabits();
    setState(() {
      _habits = habits;
      _loading = false;
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  double _completionForDay(DateTime day) {
    if (_habits.isEmpty) return 0;
    final dateStr = _formatDate(day);
    final doneCount = _habits.where((h) => h.completedDates.contains(dateStr)).length;
    return doneCount / _habits.length;
  }

  Color _colorForCompletion(double pct) {
    if (pct == 0) return Colors.grey.shade200;
    if (pct < 0.5) return Colors.orange.shade200;
    if (pct < 1.0) return Colors.lightGreen.shade300;
    return Colors.green.shade600;
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month - 1];
  }

  String _weekdayName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return names[weekday - 1];
  }

  void _showDayDetail(DateTime date) {
    final dateStr = _formatDate(date);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_weekdayName(date.weekday)}, ${_monthName(date.month)} ${date.day}'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _habits.map((habit) {
              final done = habit.completedDates.contains(dateStr);
              return ListTile(
                leading: Icon(
                  done ? Icons.check_circle : Icons.cancel_outlined,
                  color: done ? Colors.green : Colors.grey,
                ),
                title: Text(habit.name),
                dense: true,
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_visibleMonth.year, _visibleMonth.month, 1).weekday;
    final leadingBlanks = firstWeekday % 7; // Sunday = 0, Monday = 1, ... Saturday = 6

    final monthLabel = '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';
    const weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _changeMonth(-1),
                      ),
                      Text(monthLabel, style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _changeMonth(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: weekdayLabels
                        .map((label) => Expanded(
                              child: Center(
                                child: Text(
                                  label,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  if (_habits.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Text('Add a habit first to see your calendar.'),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: daysInMonth + leadingBlanks,
                      itemBuilder: (context, index) {
                        if (index < leadingBlanks) return const SizedBox.shrink();
                        final dayNum = index - leadingBlanks + 1;
                        final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNum);
                        final pct = _completionForDay(date);
                        return GestureDetector(
                          onTap: () => _showDayDetail(date),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _colorForCompletion(pct),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$dayNum', style: const TextStyle(fontSize: 12)),
                                Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 10)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    children: const [
                      _LegendDot(color: Colors.grey, label: '0%'),
                      _LegendDot(color: Colors.orange, label: '<50%'),
                      _LegendDot(color: Colors.lightGreen, label: '<100%'),
                      _LegendDot(color: Colors.green, label: '100%'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}