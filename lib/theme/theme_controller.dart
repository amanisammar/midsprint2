import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController() {
    _load();
  }

  static const _prefKey = 'themeKey';

  String _themeKey = 'teal';
  String get themeKey => _themeKey;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_prefKey);
    if (stored != null && _themes.containsKey(stored)) {
      _themeKey = stored;
      notifyListeners();
    }
  }

  Future<void> setTheme(String key) async {
    if (!_themes.containsKey(key)) return;
    _themeKey = key;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, key);
  }

  ThemeData get theme => _buildTheme(_themes[_themeKey]!);

  List<ThemeChoice> get choices => _themes.entries
      .map((e) => ThemeChoice(key: e.key, name: e.value.name, primary: e.value.seedColor))
      .toList();
}

class ThemeChoice {
  final String key;
  final String name;
  final Color primary;
  ThemeChoice({required this.key, required this.name, required this.primary});
}

class _ThemeSpec {
  final String name;
  final Color seedColor;
  final Color secondary;
  final Color surface;
  const _ThemeSpec({
    required this.name,
    required this.seedColor,
    required this.secondary,
    required this.surface,
  });
}

final Map<String, _ThemeSpec> _themes = {
  'teal': const _ThemeSpec(
    name: 'Teal Breeze',
    seedColor: Color(0xFF2EC4B6),
    secondary: Color(0xFF4D96FF),
    surface: Color(0xFFF7F4EF),
  ),
  'ocean': const _ThemeSpec(
    name: 'Ocean Blue',
    seedColor: Color(0xFF1976D2),
    secondary: Color(0xFF64B5F6),
    surface: Color(0xFFF5F8FF),
  ),
  'sunset': const _ThemeSpec(
    name: 'Sunset Glow',
    seedColor: Color(0xFFFF7043),
    secondary: Color(0xFFFFB74D),
    surface: Color(0xFFFFF8F3),
  ),
};

ThemeData _buildTheme(_ThemeSpec spec) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: spec.seedColor,
      primary: spec.seedColor,
      secondary: spec.secondary,
      surface: spec.surface,
    ),
    scaffoldBackgroundColor: spec.surface,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      labelStyle: const TextStyle(color: Color(0xFF2E2E2E)),
      floatingLabelStyle: TextStyle(color: spec.seedColor),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDADADA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: spec.seedColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: spec.seedColor,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black,
    ),
  );
}
