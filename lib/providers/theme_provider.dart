import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = purpleTheme;
  String currentTheme = 'purple';

  ThemeData get themeData => _themeData;

  void setTheme(String theme) async {
    switch (theme) {
      case 'light':
        _themeData = ThemeData.light();
        break;
      case 'dark':
        _themeData = ThemeData.dark();
        break;
      default:
        _themeData = purpleTheme;
    }
    currentTheme = theme;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setTheme(prefs.getString('theme') ?? 'purple');
  }

  ThemeData getThemeByName(String name) {
    switch (name) {
      case 'dark':
        return ThemeData.dark().copyWith(
          primaryColor: Colors.deepPurple,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          scaffoldBackgroundColor: Colors.black,
        );
      case 'purple':
        return ThemeData.light().copyWith(
          primaryColor: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.deepPurple.shade50,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        );
      case 'light':
      default:
        return ThemeData.light().copyWith(
          primaryColor: Colors.blue,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

}

final purpleTheme = ThemeData(
  primarySwatch: Colors.purple,
  brightness: Brightness.light,
);
