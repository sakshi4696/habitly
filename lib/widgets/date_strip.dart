import 'package:flutter/material.dart';

class DateStrip extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const DateStrip({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  static const _rangeDays = 60; // how many days before/after today are scrollable
  static const _itemWidth = 60.0;
  static const _weekdayAbbrev = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

  late final DateTime _anchor; // "today", fixed once when the strip is built
  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, now.day);
    _controller = ScrollController();

    // Jump so "today" starts near the left edge rather than the very start
    // of the whole scrollable range.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo((_rangeDays * _itemWidth) - 20);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final totalDays = _rangeDays * 2 + 1;
    final accent = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 84,
      child: ListView.builder(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final date = _anchor.subtract(Duration(days: _rangeDays)).add(Duration(days: index));
          final isSelected = _isSameDay(date, widget.selectedDate);
          final isToday = _isSameDay(date, _anchor);

          return GestureDetector(
            onTap: () => widget.onDateSelected(date),
            child: Container(
              width: _itemWidth - 8,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _weekdayAbbrev[date.weekday % 7],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accent : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : isToday
                                ? accent.withOpacity(0.5)
                                : Colors.grey.shade200,
                        width: isToday && !isSelected ? 2 : 1.5,
                      ),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
