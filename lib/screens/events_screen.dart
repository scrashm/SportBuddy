import 'package:flutter/material.dart';

/// Экран мероприятий (заглушка)
/// TODO: Реализовать отображение ивентов
class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мероприятия')),
      body: const Center(child: Text('Здесь будут мероприятия')), 
    );
  }
} 