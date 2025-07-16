import 'package:flutter/material.dart';

class YandexMap extends StatelessWidget {
  const YandexMap({super.key, dynamic initialCameraPosition});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class CameraPosition {
  const CameraPosition({required target, required zoom});
}

class Point {
  const Point({required double latitude, required double longitude});
} 