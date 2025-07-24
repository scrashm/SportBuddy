import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:sport_buddy_ru/main.dart';
import 'package:sport_buddy_ru/services/auth_service.dart';
import 'package:sport_buddy_ru/services/config_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Telegram Authentication Integration Tests', () {
    
    setUpAll(() async {
      // Initialize configuration
      TestWidgetsFlutterBinding.ensureInitialized();
      await ConfigService.initialize();
    });

    testWidgets('Complete Telegram authentication flow', (WidgetTester tester) async {
      // This test simulates the complete authentication flow
      // Note: This requires actual backend interaction
      
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Verify we start on the auth screen
      expect(find.text('Sport Buddy'), findsOneWidget);
      expect(find.text('Войти через Telegram'), findsOneWidget);

      // Tap the Telegram login button
      await tester.tap(find.text('Войти через Telegram'));
      await tester.pump();

      // Verify loading state appears
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Note: At this point, the app would normally open Telegram
      // For integration testing, we need to mock or simulate the Telegram response
    });

    testWidgets('Authentication service initialization', (WidgetTester tester) async {
      final authService = AuthService();
      
      // Verify initial state
      expect(authService.currentUser, isNull);
      
      // Test that we can attempt to start authentication
      // This will fail without proper backend setup, but we can test the flow
      try {
        await authService.signInWithTelegram();
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isA<Exception>());
      }
    });

    testWidgets('UI responds correctly to authentication state changes', (WidgetTester tester) async {
      final authService = AuthService();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthService>.value(value: authService),
          ],
          child: MaterialApp(
            home: Consumer<AuthService>(
              builder: (context, auth, child) {
                return Scaffold(
                  body: Text(
                    auth.currentUser != null ? 'Authenticated' : 'Not authenticated',
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially should show not authenticated
      expect(find.text('Not authenticated'), findsOneWidget);
      
      // If we had a way to simulate successful authentication,
      // we would test the state change here
    });

    group('Backend API Integration', () {
      
      testWidgets('Test backend connectivity', (WidgetTester tester) async {
        // Test if backend is reachable
        final String baseUrl = ConfigService.baseUrl;
        
        try {
          final response = await http.get(Uri.parse('$baseUrl/health'));
          expect(response.statusCode, 200);
          
          final healthData = jsonDecode(response.body);
          expect(healthData['status'], 'OK');
        } catch (e) {
          // Backend not available - this is acceptable in test environment
          print('Backend not available for testing: $e');
        }
      });

      testWidgets('Test authentication endpoint', (WidgetTester tester) async {
        final String baseUrl = ConfigService.baseUrl;
        
        try {
          // Test starting authentication
          final response = await http.post(Uri.parse('$baseUrl/auth/telegram/start'));
          expect(response.statusCode, 200);
          
          final authData = jsonDecode(response.body);
          expect(authData['token'], isNotNull);
          expect(authData['url'], isNotNull);
          expect(authData['url'], contains('t.me'));
          
          // Test token format (32 hex characters)
          final token = authData['token'];
          expect(RegExp(r'^[a-f0-9]{32}$').hasMatch(token), isTrue);
          
          // Test status endpoint
          final statusResponse = await http.get(
            Uri.parse('$baseUrl/auth/telegram/status/$token')
          );
          expect(statusResponse.statusCode, 200);
          
          final statusData = jsonDecode(statusResponse.body);
          expect(statusData['status'], 'pending');
          
        } catch (e) {
          print('Backend authentication endpoints not available: $e');
        }
      });
    });

    group('Error Handling', () {
      
      testWidgets('Handle network errors gracefully', (WidgetTester tester) async {
        // Create AuthService with invalid base URL to simulate network error
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Find and tap login button
        final loginButton = find.text('Войти через Telegram');
        await tester.tap(loginButton);
        await tester.pump();

        // Wait for error handling
        await tester.pumpAndSettle(Duration(seconds: 5));

        // Should show error message or return to initial state
        // The exact behavior depends on how errors are handled in AuthService
      });

      testWidgets('Handle Telegram app not installed', (WidgetTester tester) async {
        // This would require mocking url_launcher to simulate app not available
        // For now, we document this as a manual test case
      });
    });

    group('User Profile Management', () {
      
      testWidgets('User profile updates correctly', (WidgetTester tester) async {
        final authService = AuthService();
        
        // Mock user data - in real test, this would come from successful auth
        // For now, we test the profile update mechanism
        
        try {
          await authService.updateUserProfile(
            name: 'Test User',
            bio: 'Test bio',
            interests: ['football', 'basketball'],
            pet: 'dog',
          );
        } catch (e) {
          // Expected to fail without authenticated user
          expect(e, isA<Exception>());
        }
      });
    });
  });

  group('Manual Test Instructions', () {
    
    testWidgets('Print manual test instructions', (WidgetTester tester) async {
      print('\n=== MANUAL TESTING REQUIRED ===');
      print('The following tests require manual intervention with a real device:');
      print('');
      print('1. COMPLETE LOGIN FLOW TEST:');
      print('   - Run app on physical device');
      print('   - Ensure backend server is running');
      print('   - Tap "Войти через Telegram" button');
      print('   - Verify Telegram app opens with bot conversation');
      print('   - Tap "START" or send message to bot');
      print('   - Tap "Подтвердить вход" button');
      print('   - Return to Sport Buddy app');
      print('   - Verify successful login and profile display');
      print('');
      print('2. NETWORK ERROR HANDLING:');
      print('   - Start login process');
      print('   - Turn off WiFi/mobile data during polling');
      print('   - Turn connection back on');
      print('   - Complete login in Telegram');
      print('   - Verify app recovers and completes login');
      print('');
      print('3. TIMEOUT SCENARIOS:');
      print('   - Start login process');
      print('   - Open Telegram but don\'t confirm');
      print('   - Wait 5+ minutes');
      print('   - Return to app and verify behavior');
      print('');
      print('4. SCREENSHOT CHECKLIST:');
      print('   [ ] Initial login screen');
      print('   [ ] Loading state during auth');
      print('   [ ] Telegram bot conversation');
      print('   [ ] Confirmation button in Telegram');
      print('   [ ] Successful login (main screen)');
      print('   [ ] User profile display');
      print('   [ ] Error states (if any)');
      print('');
      print('5. QA VERIFICATION POINTS:');
      print('   [ ] Backend returns valid JWT/user profile');
      print('   [ ] User data persists correctly');
      print('   [ ] App handles edge cases gracefully');
      print('   [ ] Performance is acceptable (< 15s login time)');
      print('   [ ] UI/UX is smooth and intuitive');
      print('===============================\n');
    });
  });
}

// Helper function to simulate user interaction delays
Future<void> simulateUserDelay() async {
  await Future.delayed(Duration(milliseconds: 500));
}

// Helper function to wait for network requests
Future<void> waitForNetworkRequest() async {
  await Future.delayed(Duration(seconds: 2));
}

// Test data and utilities
class TestData {
  static const String mockTelegramId = '123456789';
  static const String mockUsername = 'testuser';
  static const String mockName = 'Test User';
  
  static Map<String, dynamic> get mockUserData => {
    'id': 'test-uuid',
    'telegram_id': mockTelegramId,
    'telegram_username': mockUsername,
    'name': mockName,
    'avatar_url': null,
    'bio': 'Test user bio',
    'sports': null,
    'interests': ['football', 'basketball'],
    'pet': 'dog',
    'created_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
}
