import 'package:flutter/material.dart';
import 'map_screen.dart';
import 'search_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';

/// Главный экран приложения с нижней навигацией
class MainScreen extends StatefulWidget {
  final List<String> sports;
  final String? avatar;
  final String? bio;
  const MainScreen({super.key, this.sports = const [], this.avatar, this.bio});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Список экранов для навигации, ProfileScreen получает sports, avatar, bio
    final List<Widget> screens = <Widget>[
      const MapScreen(),
      const SearchScreen(),
      const EventsScreen(),
      ProfileScreen(sports: widget.sports, avatar: widget.avatar, bio: widget.bio),
    ];

    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Карта',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Мероприятия',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
} 