import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Theme Switcher
            DropdownButton<String>(
              value: themeProvider.currentTheme,
              items: ['purple', 'light', 'dark'].map((theme) {
                return DropdownMenuItem(
                  value: theme,
                  child: Text(theme),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  themeProvider.setTheme(value);
                }
              },
            ),
            const SizedBox(height: 20),

            // Language Switcher
            DropdownButton<String>(
              value: localeProvider.currentLocale.languageCode,
              items: ['en', 'ru', 'kk'].map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(Locale(value));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
