import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_todo/providers/theme_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = themeProvider.currentTheme;

    // Theme-specific colors
    final Color backgroundColor = currentTheme == 'purple'
        ? Colors.deepPurple.shade50
        : currentTheme == 'dark'
        ? Colors.grey.shade900
        : Colors.white;

    final Color iconColor = currentTheme == 'purple'
        ? Colors.deepPurple
        : currentTheme == 'dark'
        ? Colors.white
        : Colors.lightBlue;

    final Color textColor = currentTheme == 'dark' ? Colors.white : Colors.black;

    final Color buttonColor = currentTheme == 'purple'
        ? Colors.deepPurple
        : currentTheme == 'dark'
        ? Colors.deepPurple
        : Colors.lightBlue;

    return Container(
      color: backgroundColor,
      width: double.infinity,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 100, color: iconColor),
            const SizedBox(height: 20),
            Text(
              "${loc.profile}: ${user?.email ?? 'No user'}",
              style: TextStyle(fontSize: 18, color: textColor),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: Text(loc.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
