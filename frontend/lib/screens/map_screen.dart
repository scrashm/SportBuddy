import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Импортируем YandexMapKit только если не web
// ignore: uri_does_not_exist
import 'package:yandex_mapkit/yandex_mapkit.dart' if (dart.library.html) 'map_screen_stub.dart';

/// Экран с картой спорта
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  Widget _buildMap() {
    if (kIsWeb) {
      return const Center(child: Text('Карта недоступна в web-версии'));
    } else {
      // ignore: prefer_const_constructors
      return YandexMap(
        initialCameraPosition: CameraPosition(
          target: Point(latitude: 59.9343, longitude: 30.3351),
          zoom: 11,
        ),
      );
    }
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