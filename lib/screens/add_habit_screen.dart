import 'package:flutter/material.dart';

class AddHabitScreen extends StatefulWidget {
  final List<String> existingNames;

  const AddHabitScreen({super.key, required this.existingNames});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final trimmed = _controller.text.trim();

    if (trimmed.isEmpty) {
      setState(() => _errorText = 'Please enter a habit name');
      return;
    }

    final isDuplicate = widget.existingNames
        .any((name) => name.toLowerCase() == trimmed.toLowerCase());
    if (isDuplicate) {
      setState(() => _errorText = 'A habit with this name already exists');
      return;
    }

    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Drink water',
                border: const OutlineInputBorder(),
                errorText: _errorText,
              ),
              onChanged: (_) {
                // Clear the error as soon as they start fixing it, rather
                // than leaving a stale message up while they type.
                if (_errorText != null) setState(() => _errorText = null);
              },
              onSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleSave,
              child: const Text('Save Habit'),
            ),
          ],
        ),
      ),
    );
  }
}