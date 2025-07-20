import 'package:flutter/material.dart';

/// Экран поиска напарников (заглушка)
/// TODO: Реализовать поиск напарников
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Поиск напарников')),
      body: const Center(child: Text('Здесь будет поиск напарников')), 
    );
  }
} 