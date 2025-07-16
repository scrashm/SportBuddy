// Главная точка входа в приложение
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// Импортируем экраны из отдельной папки
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile_onboarding_screen.dart';
import 'screens/avatar_bio_onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

/// Корневой виджет приложения
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Флаг авторизации пользователя
  bool _isAuthorized = false;
  bool _profileCompleted = false;
  List<String> _selectedSports = [];
  String? _avatar;
  String? _bio;

  // 0 - не начато, 1 - выбран спорт, 2 - выбран аватар и bio
  int _onboardingStep = 0;

  // Вызывается после успешной авторизации
  void _onAuthorized() {
    setState(() {
      _isAuthorized = true;
      _profileCompleted = false;
      _onboardingStep = 0;
    });
  }

  void _onProfileSportsCompleted(List<String> sports) {
    setState(() {
      _selectedSports = sports;
      _onboardingStep = 1;
    });
  }

  void _onAvatarBioCompleted(String avatar, String bio) {
    setState(() {
      _avatar = avatar;
      _bio = bio;
      _profileCompleted = true;
      _onboardingStep = 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (!_isAuthorized) {
      homeWidget = AuthScreen(onAuthorized: _onAuthorized);
    } else if (!_profileCompleted && _onboardingStep == 0) {
      homeWidget = ProfileOnboardingScreen(onComplete: _onProfileSportsCompleted);
    } else if (!_profileCompleted && _onboardingStep == 1) {
      homeWidget = AvatarBioOnboardingScreen(onComplete: _onAvatarBioCompleted);
    } else {
      homeWidget = MainScreen(
        sports: _selectedSports,
        avatar: _avatar,
        bio: _bio,
      );
    }
    return MaterialApp(
      title: 'Sport Buddy RU',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [
        Locale('ru', 'RU'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: homeWidget,
    );
  }
}
