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

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Buddy RU',
      theme: ThemeData(
        fontFamily: 'NotoSans',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppFlow(),
    );
  }
}

class AppFlow extends StatefulWidget {
  const AppFlow({super.key});
  @override
  State<AppFlow> createState() => _AppFlowState();
}

class _AppFlowState extends State<AppFlow> {
  List<String> _selectedSports = [];
  String? _avatar;
  String? _bio;
  String? _work;
  String? _study;
  String? _pet;

  PageRouteBuilder _slide(Widget child) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => child,
      transitionsBuilder: (_, animation, __, child) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.ease));
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreen(
      onAuthorized: () {
        Navigator.of(context).push(_slide(ProfileOnboardingScreen(
          onComplete: (sports) {
            setState(() => _selectedSports = sports);
            Navigator.of(context).push(_slide(AvatarBioOnboardingScreen(
              onComplete: (avatar, bio, work, study, pet) {
                setState(() {
                  _avatar = avatar;
                  _bio = bio;
                  _work = work;
                  _study = study;
                  _pet = pet;
                });
                Navigator.of(context).pushReplacement(_slide(MainScreen(
                  sports: _selectedSports,
                  avatar: _avatar,
                  bio: _bio,
                  work: _work,
                  study: _study,
                  pet: _pet,
                )));
              },
            )));
          },
        )));
      },
    );
  }
}
