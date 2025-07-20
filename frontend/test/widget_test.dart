// Базовый виджет-тест для Flutter-приложения.
//
// Этот тест проверяет, что при нажатии на кнопку счетчик увеличивается на 1.
// Для взаимодействия с виджетами используется WidgetTester из пакета flutter_test.
//
// Подробнее о тестировании: https://docs.flutter.dev/testing

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sport_buddy_ru/main.dart';

void main() {
  testWidgets('Проверка увеличения счетчика по нажатию', (WidgetTester tester) async {
    // Строим приложение и инициируем первый кадр (отрисовку)
    await tester.pumpWidget(const MyApp());

    // Проверяем, что на экране есть текст "0" (счетчик по умолчанию)
    expect(find.text('0'), findsOneWidget);
    // Проверяем, что текста "1" еще нет
    expect(find.text('1'), findsNothing);

    // Имитируем нажатие на иконку "+"
    await tester.tap(find.byIcon(Icons.add));
    // Запускаем перерисовку после действия
    await tester.pump();

    // Проверяем, что теперь текста "0" нет, а "1" появился
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
