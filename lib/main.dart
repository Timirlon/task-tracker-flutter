import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:simple_todo/pages/home_page.dart';
import 'package:simple_todo/pages/login_page.dart';
import 'package:simple_todo/providers/theme_provider.dart';
import 'package:simple_todo/providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: dotenv.env['API_KEY']!,
            authDomain: dotenv.env['AUTH_DOMAIN']!,
            projectId: dotenv.env['PROJECT_ID']!,
            storageBucket: dotenv.env['STORAGE_BUCKET']!,
            messagingSenderId: dotenv.env['MESSAGING_SENDER_ID']!,
            appId: dotenv.env['APP_ID']!,
            measurementId: dotenv.env['MEASUREMENT_ID']!)
    );
  } else {
    await Firebase.initializeApp();
  }

  final themeProvider = ThemeProvider();
  final localeProvider = LocaleProvider();
  await themeProvider.loadTheme();
  await localeProvider.loadLocale();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: localeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          locale: localeProvider.currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ru'),
            Locale('kk'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                return const HomePage();
              } else {
                return const LoginPage();
              }
            },
          ),
        );
      },
    );
  }

}
