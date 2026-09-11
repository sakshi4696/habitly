import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Habit> _habits = [];
  bool _loading = true;

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

  double _completionForDay(DateTime day) {
    // Only count habits that had actually been created (or backfilled to
    // cover) this day — a habit added today shouldn't drag down the score
    // of a day before it existed.
    final eligibleHabits = _habits.where((h) => !_effectiveStart(h).isAfter(day)).toList();
    if (eligibleHabits.isEmpty) return 0;
    final dateStr = _formatDate(day);
    final doneCount = eligibleHabits.where((h) => h.completedDates.contains(dateStr)).length;
    return doneCount / eligibleHabits.length;
  }

  // A habit's real starting point: whichever is earlier, its official
  // createdAt, or the earliest date the user has actually logged completion
  // for. This matters when someone backfills past days after creating a
  // habit — the window should stretch back to cover that, not ignore it.
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

  // Average completion this month, per habit — each habit only counts from
  // whichever is later: the 1st of the month, or its effective start date.
  // A habit added on the 5th isn't penalized for the 4 days before it existed,
  // unless the user backfilled earlier days, in which case those count too.
  double _monthAverage() {
    final now = _dateOnly(DateTime.now());
    final monthStart = DateTime(now.year, now.month, 1);

    double totalPct = 0;
    int countedHabits = 0;

    for (final habit in _habits) {
      final effectiveStart = _effectiveStart(habit);
      final windowStart = effectiveStart.isAfter(monthStart) ? effectiveStart : monthStart;

      if (windowStart.isAfter(now)) continue; // habit was created in the future somehow — skip

      final daysConsidered = now.difference(windowStart).inDays + 1;
      int doneCount = 0;
      for (int i = 0; i < daysConsidered; i++) {
        final date = windowStart.add(Duration(days: i));
        if (habit.completedDates.contains(_formatDate(date))) doneCount++;
      }

      totalPct += doneCount / daysConsidered;
      countedHabits++;
    }

    return countedHabits == 0 ? 0 : totalPct / countedHabits;
  }

  // Finds the single best day this month. When multiple days tie on
  // percentage, the day with more habits actually done wins (100% of 5 beats
  // 100% of 1). If that's still tied, the more recent day wins.
  MapEntry<DateTime, double>? _bestDay() {
    final now = DateTime.now();
    DateTime? bestDate;
    double bestPct = -1;
    int bestDoneCount = -1;

    for (int day = 1; day <= now.day; day++) {
      final date = DateTime(now.year, now.month, day);
      final eligibleHabits = _habits.where((h) => !_effectiveStart(h).isAfter(date)).toList();
      if (eligibleHabits.isEmpty) continue;

      final dateStr = _formatDate(date);
      final doneCount = eligibleHabits.where((h) => h.completedDates.contains(dateStr)).length;
      final pct = doneCount / eligibleHabits.length;

      final isBetter = pct > bestPct ||
          (pct == bestPct && doneCount > bestDoneCount) ||
          (pct == bestPct && doneCount == bestDoneCount); // later day in the loop = more recent, so ties naturally favor it by just overwriting

      if (isBetter) {
        bestPct = pct;
        bestDoneCount = doneCount;
        bestDate = date;
      }
    }
    if (bestDate == null || bestPct <= 0) return null;
    return MapEntry(bestDate, bestPct);
  }

  // Longest run of consecutive days a single habit has ever had, all-time.
  int _longestStreak(List<String> dateStrings) {
    if (dateStrings.isEmpty) return 0;
    final dates = dateStrings.map(DateTime.parse).toList()..sort();

    int longest = 1;
    int current = 1;
    for (int i = 1; i < dates.length; i++) {
      final gap = dates[i].difference(dates[i - 1]).inDays;
      if (gap == 1) {
        current++;
      } else if (gap > 1) {
        current = 1;
      }
      if (current > longest) longest = current;
    }
    return longest;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final monthLabel = monthNames[now.month - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Stats')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _habits.isEmpty
              ? const Center(child: Text('Add a habit first to see stats.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '$monthLabel ${now.year}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _StatCard(
                        icon: Icons.percent,
                        label: 'Average completion this month',
                        value: '${(_monthAverage() * 100).round()}%',
                      ),
                      const SizedBox(height: 12),
                      _buildBestDayCard(monthNames),
                      const SizedBox(height: 24),
                      Text(
                        'Longest streaks (all-time)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ..._habits.map((habit) {
                        final best = _longestStreak(habit.completedDates);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.emoji_events_outlined, color: Colors.amber),
                            title: Text(habit.name),
                            trailing: Text(
                              '$best day${best == 1 ? '' : 's'}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }

  Widget _buildBestDayCard(List<String> monthNames) {
    final best = _bestDay();
    if (best == null) {
      return const _StatCard(
        icon: Icons.star_border,
        label: 'Best day this month',
        value: 'No data yet',
      );
    }
    final date = best.key;
    final pct = best.value;
    return _StatCard(
      icon: Icons.star,
      label: 'Best day this month',
      value: '${monthNames[date.month - 1]} ${date.day} (${(pct * 100).round()}%)',
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}