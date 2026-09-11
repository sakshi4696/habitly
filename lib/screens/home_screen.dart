import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../services/habit_storage.dart';
import '../widgets/habit_card.dart';
import '../widgets/date_strip.dart';
import 'add_habit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Habit> _habits = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

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

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _isFutureSelected => _selectedDate.isAfter(_dateOnly(DateTime.now()));

  Future<void> _toggleForSelectedDate(Habit habit) async {
    if (_isFutureSelected) return; // safety net — UI already disables this
    final dateStr = _formatDate(_selectedDate);
    setState(() {
      if (habit.completedDates.contains(dateStr)) {
        habit.completedDates.remove(dateStr);
      } else {
        habit.completedDates.add(dateStr);
      }
    });
    await HabitStorage.saveHabits(_habits);
  }

  Future<void> _addHabit() async {
    final name = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHabitScreen(
          existingNames: _habits.map((h) => h.name).toList(),
        ),
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() {
        _habits.add(Habit(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.trim(),
        ));
      });
      await HabitStorage.saveHabits(_habits);
    }
  }

  Future<void> _deleteHabit(Habit habit) async {
    setState(() {
      _habits.removeWhere((h) => h.id == habit.id);
    });
    await HabitStorage.saveHabits(_habits);
  }

  bool _isDuplicateName(String name, {required String excludingId}) {
    return _habits.any((h) =>
        h.id != excludingId && h.name.toLowerCase() == name.toLowerCase());
  }

  Future<void> _editHabit(Habit habit) async {
    final controller = TextEditingController(text: habit.name);
    String? errorText;

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Habit'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(errorText: errorText),
            onChanged: (_) {
              if (errorText != null) setDialogState(() => errorText = null);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isEmpty) {
                  setDialogState(() => errorText = 'Name cannot be empty');
                  return;
                }
                if (_isDuplicateName(trimmed, excludingId: habit.id)) {
                  setDialogState(() => errorText = 'A habit with this name already exists');
                  return;
                }
                Navigator.pop(context, trimmed);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (newName != null && newName.trim().isNotEmpty) {
      setState(() => habit.name = newName.trim());
      await HabitStorage.saveHabits(_habits);
    }
  }

  String _selectedDateLabel() {
    final today = DateTime.now();
    if (_isSameDay(_selectedDate, today)) return 'Today';

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                DateStrip(
                  selectedDate: _selectedDate,
                  onDateSelected: (date) => setState(() => _selectedDate = date),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        _selectedDateLabel(),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_isFutureSelected) ...[
                        const SizedBox(width: 8),
                        const Text(
                          "(can't log future days yet)",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: _habits.isEmpty
                      ? const Center(child: Text('No habits yet. Tap + to add one.'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _habits.length,
                          itemBuilder: (context, index) {
                            final habit = _habits[index];
                            final done = habit.completedDates
                                .contains(_formatDate(_selectedDate));
                            return HabitCard(
                              habit: habit,
                              done: done,
                              enabled: !_isFutureSelected,
                              onToggle: () => _toggleForSelectedDate(habit),
                              onDelete: () => _deleteHabit(habit),
                              onEdit: () => _editHabit(habit),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}