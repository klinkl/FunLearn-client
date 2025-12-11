import 'package:flutter/material.dart';
import 'screens/learning_view.dart';
import 'screens/cards_list_view.dart';
import '../theme/customColors.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('themeMode') ?? 'light';
  runApp(MyApp(initialMode: _parseThemeMode(saved)));
}

ThemeMode _parseThemeMode(String s) {
  switch (s) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class MyApp extends StatefulWidget {
  final ThemeMode initialMode;
  const MyApp({super.key, required this.initialMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialMode;
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _themeMode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
        ),
        extensions: [
          const CustomColors(
            card: Colors.white54,
            navigationBar: Colors.lightBlue,
            navigationIcon: Colors.black,
            addButton: Colors.white,
          ),
        ],
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF7C4DFF),
          onPrimary: Colors.white,
          secondary: const Color(0xFFFFC107),
          onSecondary: Colors.black,
          surface: const Color(0xFF121212),
          onSurface: Colors.white,
          error: Colors.red.shade400,
          onError: Colors.black,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.black,
        ),
        extensions: [
          const CustomColors(
            card: Color(0xFF1E1E1E),
            navigationBar: Color(0xFF7C4DFF),
            navigationIcon: Colors.white,
            addButton: Color(0xFF1E1E1E),
          ),
        ],
      ),
      themeMode: _themeMode,
      home: MyHomePage(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}
