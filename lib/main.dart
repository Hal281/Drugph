import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'ui/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  runApp(const DrugDosageApp());
}

class DrugDosageApp extends StatefulWidget {
  const DrugDosageApp({super.key});

  @override
  State<DrugDosageApp> createState() => _DrugDosageAppState();
}

class _DrugDosageAppState extends State<DrugDosageApp> {
  Locale _locale = const Locale('th', 'TH'); // Default Thai

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drugph Clinical Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: _locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('th', 'TH'),
      ],
      home: HomeScreen(
        currentLocale: _locale,
        onLocaleChange: setLocale,
      ),
    );
  }
}
