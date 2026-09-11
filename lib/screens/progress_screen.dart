import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';

enum Granularity { week, month, year }

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  List<Habit> _habits = [];
  bool _loading = true;
  Granularity _granularity = Granularity.week;
  DateTime _referenceDate = DateTime.now();

  static const _monthAbbrev = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _monthFull = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _weekdayAbbrev = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

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

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  // A habit's real starting point: whichever is earlier, its official
  // createdAt, or the earliest date the user has actually logged completion
  // for (covers backfilled past days). Same logic as the Stats tab.
  DateTime _effectiveStart(Habit habit) {
    DateTime start = _dateOnly(habit.createdAt);
    if (habit.completedDates.isNotEmpty) {
      final earliestCompleted = habit.completedDates
          .map(DateTime.parse)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (earliestCompleted.isBefore(start)) start = earliestCompleted;
    }
    return start;
  }

  (DateTime, DateTime) _computeRange() {
    switch (_granularity) {
      case Granularity.week:
        final weekday = _referenceDate.weekday % 7;
        final start = DateTime(_referenceDate.year, _referenceDate.month, _referenceDate.day)
            .subtract(Duration(days: weekday));
        return (start, start.add(const Duration(days: 6)));
      case Granularity.month:
        final start = DateTime(_referenceDate.year, _referenceDate.month, 1);
        final end = DateTime(
          _referenceDate.year,
          _referenceDate.month,
          _daysInMonth(_referenceDate.year, _referenceDate.month),
        );
        return (start, end);
      case Granularity.year:
        return (DateTime(_referenceDate.year, 1, 1), DateTime(_referenceDate.year, 12, 31));
    }
  }

  List<DateTime> _allDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var d = start;
    while (!d.isAfter(end)) {
      days.add(d);
      d = d.add(const Duration(days: 1));
    }
    return days;
  }

  // Met % for a habit within [start, end] — clipped so days before the
  // habit's effective start never count against it, AND days after today
  // never count against it either, since a future day hasn't happened yet
  // and can't fairly be scored as "missed."
  double _metPercent(Habit habit, DateTime start, DateTime end) {
    final effStart = _effectiveStart(habit);
    final clippedStart = effStart.isAfter(start) ? effStart : start;

    final today = _dateOnly(DateTime.now());
    final clippedEnd = end.isAfter(today) ? today : end;

    if (clippedStart.isAfter(clippedEnd)) return 0; // no elapsed days yet in this range

    final days = _allDaysInRange(clippedStart, clippedEnd);
    if (days.isEmpty) return 0;
    final doneCount = days.where((d) => habit.completedDates.contains(_formatDate(d))).length;
    return doneCount / days.length;
  }

  int _longestStreakInRange(Habit habit, DateTime start, DateTime end) {
    final days = _allDaysInRange(start, end);
    int longest = 0;
    int current = 0;
    for (final d in days) {
      if (habit.completedDates.contains(_formatDate(d))) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  void _changePeriod(int delta) {
    setState(() {
      switch (_granularity) {
        case Granularity.week:
          _referenceDate = _referenceDate.add(Duration(days: 7 * delta));
          break;
        case Granularity.month:
          _referenceDate = DateTime(_referenceDate.year, _referenceDate.month + delta, 1);
          break;
        case Granularity.year:
          _referenceDate = DateTime(_referenceDate.year + delta, 1, 1);
          break;
      }
    });
  }

  String _rangeLabel() {
    final (start, end) = _computeRange();
    switch (_granularity) {
      case Granularity.week:
        if (start.month == end.month) {
          return '${_monthAbbrev[start.month - 1]} ${start.day} - ${end.day}, ${start.year}';
        }
        return '${_monthAbbrev[start.month - 1]} ${start.day} - '
            '${_monthAbbrev[end.month - 1]} ${end.day}, ${end.year}';
      case Granularity.month:
        return '${_monthFull[_referenceDate.month - 1]} ${_referenceDate.year}';
      case Granularity.year:
        return '${_referenceDate.year}';
    }
  }

  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[const DataColumn(label: Text('Habit'))];
    if (_granularity == Granularity.year) {
      for (var m = 1; m <= 12; m++) {
        columns.add(DataColumn(label: Text(_monthAbbrev[m - 1])));
      }
    } else {
      final (start, end) = _computeRange();
      for (final d in _allDaysInRange(start, end)) {
        final label = _granularity == Granularity.week
            ? '${_weekdayAbbrev[d.weekday % 7]}\n${d.day}'
            : '${d.day}';
        columns.add(DataColumn(label: Text(label, textAlign: TextAlign.center)));
      }
    }
    columns.add(const DataColumn(label: Text('Met %')));
    columns.add(const DataColumn(label: Text('Best\nStreak')));
    return columns;
  }

  List<DataRow> _buildRows() {
    final (rangeStart, rangeEnd) = _computeRange();

    return _habits.map((habit) {
      final cells = <DataCell>[DataCell(Text(habit.name))];

      if (_granularity == Granularity.year) {
        for (var m = 1; m <= 12; m++) {
          final start = DateTime(_referenceDate.year, m, 1);
          final end = DateTime(_referenceDate.year, m, _daysInMonth(_referenceDate.year, m));
          final pct = _metPercent(habit, start, end);
          cells.add(DataCell(Text('${(pct * 100).round()}%')));
        }
      } else {
        for (final d in _allDaysInRange(rangeStart, rangeEnd)) {
          final done = habit.completedDates.contains(_formatDate(d));
          cells.add(DataCell(Icon(
            done ? Icons.check_circle : Icons.remove,
            color: done ? Colors.green : Colors.grey.shade300,
            size: 18,
          )));
        }
      }

      final metPct = _metPercent(habit, rangeStart, rangeEnd);
      cells.add(DataCell(Text('${(metPct * 100).round()}%')));
      final streak = _longestStreakInRange(habit, rangeStart, rangeEnd);
      cells.add(DataCell(Text('$streak')));

      return DataRow(cells: cells);
    }).toList();
  }

  Widget _buildMonthMiniCalendars() {
    final (rangeStart, rangeEnd) = _computeRange();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: _habits.map((habit) {
        final metPct = _metPercent(habit, rangeStart, rangeEnd);
        final streak = _longestStreakInRange(habit, rangeStart, rangeEnd);
        return _HabitMiniCalendar(
          habit: habit,
          year: _referenceDate.year,
          month: _referenceDate.month,
          completionPct: metPct,
          longestStreak: streak,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(child: Text('Add a habit first to see your progress grid.'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<Granularity>(
                        segments: const [
                          ButtonSegment(value: Granularity.week, label: Text('Week')),
                          ButtonSegment(value: Granularity.month, label: Text('Month')),
                          ButtonSegment(value: Granularity.year, label: Text('Year')),
                        ],
                        selected: {_granularity},
                        onSelectionChanged: (selection) =>
                            setState(() => _granularity = selection.first),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () => _changePeriod(-1),
                        ),
                        Text(_rangeLabel(), style: Theme.of(context).textTheme.titleMedium),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => _changePeriod(1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _granularity == Granularity.month
                          ? SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: _buildMonthMiniCalendars(),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: DataTable(
                                  columnSpacing: 16,
                                  columns: _buildColumns(),
                                  rows: _buildRows(),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
    );
  }
}

// A single habit's month shown as a plain grid of filled/empty boxes —
// no date numbers, just a shape you can recognize at a glance.
class _HabitMiniCalendar extends StatelessWidget {
  final Habit habit;
  final int year;
  final int month;
  final double completionPct;
  final int longestStreak;

  const _HabitMiniCalendar({
    required this.habit,
    required this.year,
    required this.month,
    required this.completionPct,
    required this.longestStreak,
  });

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday;
    final leadingBlanks = firstWeekday % 7;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Text(
              habit.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                ),
                itemCount: daysInMonth + leadingBlanks,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) return const SizedBox.shrink();
                  final dayNum = index - leadingBlanks + 1;
                  final date = DateTime(year, month, dayNum);
                  final done = habit.completedDates.contains(_formatDate(date));
                  return Container(
                    decoration: BoxDecoration(
                      color: done ? Colors.green.shade400 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${(completionPct * 100).round()}% met', style: const TextStyle(fontSize: 12)),
                Text('🔥 $longestStreak best', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}