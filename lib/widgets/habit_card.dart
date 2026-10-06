import 'package:flutter/material.dart';
import '../models/habit.dart';

// A small rotating palette so each habit gets a distinct pastel card —
// picked deterministically from the habit's id, so a given habit always
// lands on the same color instead of jumping around on every rebuild.
const List<Color> _cardColors = [
  Color(0xFFFFD9DC), // pink
  Color(0xFFFFE8CC), // peach
  Color(0xFFD9F2E3), // mint
  Color(0xFFDCE7FF), // periwinkle
  Color(0xFFF3E0FF), // lilac
  Color(0xFFFFF3C4), // butter
];

// Keyword → emoji, so common habits (water, sleep, run...) get a fitting
// icon instead of a generic one. Falls back to a rotating set otherwise.
const Map<String, String> _keywordEmoji = {
  'water': '💧',
  'sleep': '😴',
  'walk': '🚶',
  'run': '🏃',
  'meditat': '🧘',
  'read': '📖',
  'workout': '💪',
  'gym': '🏋️',
  'yoga': '🧘',
  'sugar': '🍬',
  'smok': '🚭',
  'journal': '📓',
  'stretch': '🤸',
  'cycl': '🚴',
  'clean': '🧹',
  'study': '📚',
  'code': '💻',
  'music': '🎵',
};

const List<String> _fallbackEmoji = ['⭐', '🌱', '🎯', '✅', '🔥', '🌸'];

String _emojiFor(Habit habit) {
  final lower = habit.name.toLowerCase();
  for (final entry in _keywordEmoji.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  final index = habit.id.hashCode.abs() % _fallbackEmoji.length;
  return _fallbackEmoji[index];
}

Color _colorFor(Habit habit) {
  final index = habit.id.hashCode.abs() % _cardColors.length;
  return _cardColors[index];
}

class HabitCard extends StatelessWidget {
  final Habit habit;
  final bool done;
  final bool enabled;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const HabitCard({
    super.key,
    required this.habit,
    required this.done,
    this.enabled = true,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${habit.name}"?'),
        content: const Text(
          'This removes it and its entire streak history. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              onDelete();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _colorFor(habit);
    final emoji = _emojiFor(habit);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 26)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streak} day streak',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.black.withOpacity(0.5)),
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') _confirmDelete(context);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
          GestureDetector(
            onTap: enabled ? onToggle : null,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.black87 : Colors.white.withOpacity(0.8),
                border: Border.all(
                  color: enabled ? Colors.black26 : Colors.black12,
                ),
              ),
              child: Icon(
                done ? Icons.check_box : Icons.check_box_outline_blank,
                size: 20,
                color: done
                    ? Colors.white
                    : (enabled ? Colors.black54 : Colors.black26),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
