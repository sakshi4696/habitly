class Habit {
  final String id;
  String name;
  List<String> completedDates; // stored as 'yyyy-MM-dd' strings
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.name,
    List<String>? completedDates,
    DateTime? createdAt,
  })  : completedDates = completedDates ?? [],
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'completedDates': completedDates,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) {
    final dates = List<String>.from(json['completedDates'] ?? []);

    // Habits saved before this field existed won't have 'createdAt'.
    // Best guess for those: use their earliest completed date, or
    // today if they have no history at all yet.
    DateTime createdAt;
    if (json['createdAt'] != null) {
      createdAt = DateTime.parse(json['createdAt']);
    } else if (dates.isNotEmpty) {
      final parsedDates = dates.map(DateTime.parse).toList()..sort();
      createdAt = parsedDates.first;
    } else {
      createdAt = DateTime.now();
    }

    return Habit(
      id: json['id'],
      name: json['name'],
      completedDates: dates,
      createdAt: createdAt,
    );
  }

  bool get isDoneToday => completedDates.contains(_formatDate(DateTime.now()));

  // Counts consecutive days ending today (or yesterday, if today isn't done yet)
  int get streak {
    int count = 0;
    DateTime day = DateTime.now();

    if (!completedDates.contains(_formatDate(day))) {
      day = day.subtract(const Duration(days: 1));
    }

    while (completedDates.contains(_formatDate(day))) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}