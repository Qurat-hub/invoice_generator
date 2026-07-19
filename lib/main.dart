import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'database/hive_helper.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hive.initFlutter() sets up storage appropriately per-platform:
  // IndexedDB on Web, app documents directory on Android/iOS/Desktop.
  // This single call is what replaces all the sqflite web-shim setup.
  await Hive.initFlutter();
  await HiveHelper.instance.init();
  runApp(const InvoiceGeneratorApp());
}

class InvoiceGeneratorApp extends StatefulWidget {
  const InvoiceGeneratorApp({super.key});

  @override
  State<InvoiceGeneratorApp> createState() => _InvoiceGeneratorAppState();
}

class _InvoiceGeneratorAppState extends State<InvoiceGeneratorApp> {
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final settings = await SettingsService.instance.loadSettings();
    if (mounted) setState(() => _darkMode = settings.darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Invoice Generator',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.light,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppColors.primary,
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
    );
  }
}
