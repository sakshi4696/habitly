import 'package:flutter/material.dart';
import 'screens/home_shell.dart';

void main() {
  runApp(const HabitTrackerApp());
}

// The app's coral/pink accent — this one color drives buttons, the
// selected day pill, and the FAB via colorSchemeSeed below.
const _seedColor = Color(0xFFFF6B6B);

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ColorScheme.fromSeed() derives a whole tonal palette from the seed
    // and picks its own shade for `primary` — for this coral seed that came
    // out visibly more muted/brownish than the seed itself, so anything
    // using colorScheme.primary (date circle, category chips, buttons)
    // looked like a different color from places using _seedColor directly
    // (the FAB). Overriding primary back to the raw seed keeps every accent
    // in the app the exact same color.
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor)
        .copyWith(primary: _seedColor, onPrimary: Colors.white);

    return MaterialApp(
      title: 'Habitly',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBFA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFBFA),
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: _seedColor.withOpacity(0.15),
          elevation: 0,
        ),
      ),
      home: const HomeShell(),
    );
  }
}
