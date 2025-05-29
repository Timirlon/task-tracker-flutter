import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:simple_todo/providers/theme_provider.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isPurpleTheme = themeProvider.currentTheme == 'purple';

    return Scaffold(
      backgroundColor: isPurpleTheme
          ? Colors.deepPurple.shade50
          : themeProvider.currentTheme == 'dark'
          ? Colors.grey.shade900
          : Colors.white,
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 80, color: Colors.deepPurple),
              SizedBox(height: 20),
              Text(
                'About This App',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This simple task tracker app was built as a final project for the Cross-Platform Development course.\n\n'
                    'It allows users to create tasks with optional descriptions, planned dates, and even attach a location.\n\n'
                    'The app supports Firebase integration, localization, theming, and more.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
