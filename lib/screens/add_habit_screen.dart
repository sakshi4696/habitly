import 'package:flutter/material.dart';

class _HabitTemplate {
  final String emoji;
  final String name;
  final List<String> categories;
  const _HabitTemplate(this.emoji, this.name, this.categories);
}

const _categories = [
  'Popular', 'Health', 'Sports', 'Mind', 'Productivity', 'Quit'
];

const _categoryIcons = {
  'Popular': Icons.local_fire_department,
  'Health': Icons.favorite,
  'Sports': Icons.directions_run,
  'Mind': Icons.self_improvement,
  'Productivity': Icons.checklist,
  'Quit': Icons.block,
};

const _templates = [
  // Popular
  _HabitTemplate('🚶', 'Walk', ['Popular', 'Sports']),
  _HabitTemplate('💧', 'Drink Water', ['Popular', 'Health']),
  _HabitTemplate('😴', 'Sleep Early', ['Popular', 'Health']),
  _HabitTemplate('🧘', 'Meditation', ['Popular', 'Health', 'Mind']),
  _HabitTemplate('🏃', 'Run', ['Popular', 'Sports']),
  _HabitTemplate('📓', 'Journal', ['Popular', 'Mind']),
  _HabitTemplate('📖', 'Read', ['Popular', 'Mind']),
  _HabitTemplate('💪', 'Workout', ['Popular', 'Sports']),
  _HabitTemplate('🍬', 'Eat Less Sugar', ['Popular', 'Health', 'Quit']),
  _HabitTemplate('⏰', 'Wake Up Early', ['Popular', 'Productivity']),

  // Health
  _HabitTemplate('🥦', 'Eat Vegetables', ['Health']),
  _HabitTemplate('💊', 'Take Vitamins', ['Health']),
  _HabitTemplate('🤸', 'Stretch', ['Health', 'Sports']),
  _HabitTemplate('🍞', 'Less Carbohydrate', ['Health', 'Quit']),
  _HabitTemplate('☕', 'Drink Less Caffeine', ['Health', 'Quit']),
  _HabitTemplate('🍺', 'Drink Less Alcohol', ['Health', 'Quit']),

  // Sports
  _HabitTemplate('🚴', 'Cycling', ['Sports']),
  _HabitTemplate('🏊', 'Swim', ['Sports']),
  _HabitTemplate('🏋️', 'Gym', ['Sports']),
  _HabitTemplate('🧘‍♀️', 'Yoga', ['Sports', 'Health']),

  // Mind
  _HabitTemplate('🙏', 'Gratitude', ['Mind']),
  _HabitTemplate('🗣️', 'Learn a Language', ['Mind']),
  _HabitTemplate('📚', 'Study', ['Productivity', 'Mind']),
  _HabitTemplate('😤', 'Complain Less', ['Mind', 'Quit']),

  // Productivity
  _HabitTemplate('🛏️', 'Make Bed', ['Productivity']),
  _HabitTemplate('📝', 'Plan the Day', ['Productivity']),
  _HabitTemplate('🚫', 'No Social Media', ['Productivity']),
  _HabitTemplate('🧹', 'Clean Up', ['Productivity']),
  _HabitTemplate('🪑', 'Sit Less', ['Productivity', 'Quit']),
  _HabitTemplate('⏳', 'Procrastinate Less', ['Productivity', 'Quit']),

  _HabitTemplate('🍳', 'Cook at Home', ['Health']),
  _HabitTemplate('📦', 'Declutter', ['Productivity']),
  _HabitTemplate('🧴', 'Skincare', ['Health']),
  _HabitTemplate('🦷', 'Floss', ['Health']),
  _HabitTemplate('🍽️', 'Early Dinner', ['Health']),
  _HabitTemplate('📞', 'Call Family', ['Mind']),

  _HabitTemplate('📵', 'No Phone Before Bed', ['Mind', 'Productivity']),
  _HabitTemplate('📱', 'Limit Screen Time', ['Quit']),
  _HabitTemplate('🌿', 'Digital Detox', ['Quit']),
  _HabitTemplate('🛌', 'Sleep 8 Hours', ['Health']),
  _HabitTemplate('🍅', 'Pomodoro Focus', ['Productivity']),
  _HabitTemplate('⏱️', 'Punctuality', ['Productivity']),

  // Quit
  _HabitTemplate('🥤', 'Drink Less Beverage', ['Quit', 'Health']),
  _HabitTemplate('🚭', 'Smoke Less', ['Quit', 'Health']),
  _HabitTemplate('🎮', 'Play Less Game', ['Quit']),
  _HabitTemplate('📺', 'Watch Less TV', ['Quit']),
  _HabitTemplate('🍟', 'No Junk Food', ['Quit', 'Health']),
  _HabitTemplate('💅', 'Bite Nails Less', ['Quit']),
];

class AddHabitScreen extends StatefulWidget {
  final List<String> existingNames;

  const AddHabitScreen({super.key, required this.existingNames});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  String _selectedCategory = 'Popular';
  final Set<String> _added = {}; // names staged to add, by lowercase
  final Set<String> _favorited = {}; // purely visual, not persisted
  // Custom (non-template) entries keep their original casing here, keyed
  // by the same lowercase form used in `_added` for de-duplication.
  final Map<String, String> _customNames = {};

  bool _isTaken(String name) {
    final lower = name.toLowerCase();
    return widget.existingNames.any((n) => n.toLowerCase() == lower) ||
        _added.contains(lower);
  }

  void _addTemplate(_HabitTemplate t) {
    if (_isTaken(t.name)) return;
    setState(() => _added.add(t.name.toLowerCase()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${t.name}"'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleFavorite(String name) {
    setState(() {
      if (_favorited.contains(name)) {
        _favorited.remove(name);
      } else {
        _favorited.add(name);
      }
    });
  }

  Future<void> _openCustomHabitSheet() async {
    final controller = TextEditingController();
    String? errorText;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Custom Habit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'e.g. Practice guitar',
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) setSheetState(() => errorText = null);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final trimmed = controller.text.trim();
                    if (trimmed.isEmpty) {
                      setSheetState(() => errorText = 'Please enter a habit name');
                      return;
                    }
                    if (_isTaken(trimmed)) {
                      setSheetState(() => errorText = 'That habit already exists');
                      return;
                    }
                    Navigator.pop(context, trimmed);
                  },
                  child: const Text('Save Habit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result != null) {
      final lower = result.toLowerCase();
      setState(() {
        _added.add(lower);
        _customNames[lower] = result;
      });
    }
  }

  void _done() {
    // We staged lowercase keys for de-duplication; recover the original
    // display-case names in the order they were added.
    final names = <String>[];
    for (final t in _templates) {
      if (_added.contains(t.name.toLowerCase())) names.add(t.name);
    }
    // Anything staged that isn't a template must be a custom entry — those
    // aren't in `_templates`, so pull them from `_added` directly, skipping
    // ones already captured above.
    final templateLower = _templates.map((t) => t.name.toLowerCase()).toSet();
    for (final lower in _added) {
      if (!templateLower.contains(lower)) {
        // Recover the original typed casing for custom entries instead of
        // falling back to the lowercase de-dup key.
        names.add(_customNames[lower] ?? lower);
      }
    }
    Navigator.pop(context, names);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _templates
        .where((t) => t.categories.contains(_selectedCategory))
        .toList();
    final accent = Theme.of(context).colorScheme.primary;

    return PopScope<Object?>(
      // System back (button or swipe gesture) must go through _done() too —
      // otherwise it silently discards every habit the user just tapped
      // "+" on, even though each one showed as added on screen.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _done();
      },
      child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _done,
        ),
        title: const Text('New Habit'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? accent : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _categoryIcons[category],
                          size: 16,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final t = filtered[index];
                final alreadyAdded = _added.contains(t.name.toLowerCase()) ||
                    widget.existingNames
                        .any((n) => n.toLowerCase() == t.name.toLowerCase());
                final favorited = _favorited.contains(t.name);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0F0F0)),
                  ),
                  child: Row(
                    children: [
                      Text(t.emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          favorited ? Icons.favorite : Icons.favorite_border,
                          color: accent,
                        ),
                        onPressed: () => _toggleFavorite(t.name),
                      ),
                      IconButton(
                        icon: Icon(
                          alreadyAdded ? Icons.check_circle : Icons.add_circle_outline,
                          color: alreadyAdded ? Colors.green : Colors.black54,
                        ),
                        onPressed: alreadyAdded ? null : () => _addTemplate(t),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 200,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          onPressed: _openCustomHabitSheet,
          child: const Text(
            'Custom Habit',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      ),
    );
  }
}
