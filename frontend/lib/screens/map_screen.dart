import 'package:flutter/material.dart';

/// Экран с картой спорта
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  Widget _buildMap() {
    // Временный placeholder пока не настроена карта
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Карта спорта — Санкт-Петербург',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Скоро здесь появится интерактивная карта\n спортивных мероприятий',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Карта спорта — Санкт-Петербург'),
      ),
      body: _buildMap(),
    );
  }
} 