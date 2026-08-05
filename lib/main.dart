import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// Global notifier for managing the theme mode across the application
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QRApp());
}

class QRApp extends StatelessWidget {
  const QRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, currentMode, __) {
        return MaterialApp(
          title: 'QR Hub',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // Light Mode Theme configuration
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Cobalt primary
              brightness: Brightness.light,
              secondary: const Color(0xFF0D9488), // Titanium Teal secondary
              surface: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF0F172A),
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          // Dark Mode Theme configuration
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB), // Cobalt primary
              brightness: Brightness.dark,
              secondary: const Color(0xFF0D9488), // Titanium Teal secondary
              surface: const Color(0xFF0F172A), // Slate 900
            ),
            scaffoldBackgroundColor: const Color(0xFF020617),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF1E293B),
              contentTextStyle: const TextStyle(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}
