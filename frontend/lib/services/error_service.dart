import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  static final Connectivity _connectivity = Connectivity();

  // Toast configurations
  static const Color _errorColor = Color(0xFFE53E3E);
  static const Color _warningColor = Color(0xFFED8936);
  static const Color _infoColor = Color(0xFF3182CE);
  static const Color _successColor = Color(0xFF38A169);

  /// Show user-friendly error toast
  static void showErrorToast(String message, {
    Toast toastLength = Toast.LENGTH_LONG,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: _errorColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show warning toast
  static void showWarningToast(String message, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: 2,
      backgroundColor: _warningColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show info toast
  static void showInfoToast(String message, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: 2,
      backgroundColor: _infoColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Show success toast
  static void showSuccessToast(String message, {
    Toast toastLength = Toast.LENGTH_SHORT,
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: gravity,
      timeInSecForIosWeb: 2,
      backgroundColor: _successColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Handle Telegram authentication errors with user-friendly messages
  static void handleTelegramAuthError(dynamic error) {
    String message;
    
    if (error.toString().contains('Failed to launch')) {
      message = 'Не удалось открыть Telegram. Убедитесь, что приложение установлено.';
    } else if (error.toString().contains('timeout') || 
               error.toString().contains('NetworkException')) {
      message = 'Проблема с подключением. Проверьте интернет-соединение.';
    } else if (error.toString().contains('Token expired')) {
      message = 'Время авторизации истекло. Попробуйте еще раз.';
    } else if (error.toString().contains('Server error') ||
               error.toString().contains('500')) {
      message = 'Временные неполадки сервера. Повторите попытку через минуту.';
    } else if (error.toString().contains('Not found') ||
               error.toString().contains('404')) {
      message = 'Сервис временно недоступен. Попробуйте позже.';
    } else {
      message = 'Произошла ошибка при входе через Telegram. Попробуйте еще раз.';
    }
    
    showErrorToast(message, toastLength: Toast.LENGTH_LONG);
  }

  /// Handle general network errors
  static void handleNetworkError(dynamic error) {
    if (error is SocketException) {
      showErrorToast(
        'Нет подключения к интернету. Проверьте сетевые настройки.',
        toastLength: Toast.LENGTH_LONG,
      );
    } else if (error.toString().contains('timeout')) {
      showErrorToast(
        'Время ожидания истекло. Попробуйте еще раз.',
        toastLength: Toast.LENGTH_LONG,
      );
    } else {
      showErrorToast(
        'Ошибка сети. Проверьте подключение и повторите попытку.',
        toastLength: Toast.LENGTH_LONG,
      );
    }
  }

  /// Check connectivity status
  static Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Show connectivity warning if offline
  static Future<void> checkConnectivityAndWarn() async {
    final isOnline = await isConnected();
    if (!isOnline) {
      showWarningToast(
        'Отсутствует подключение к интернету',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
      );
    }
  }

  /// Handle authentication timeout with retry option
  static void handleAuthTimeout(VoidCallback? onRetry) {
    showErrorToast(
      'Время авторизации истекло. Нажмите для повторной попытки.',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  /// Handle server maintenance or downtime
  static void handleServerMaintenance() {
    showInfoToast(
      'Сервер временно недоступен из-за технических работ. Попробуйте позже.',
      toastLength: Toast.LENGTH_LONG,
    );
  }

  /// Generic error handler with fallback message
  static void handleGenericError(dynamic error, {String? fallbackMessage}) {
    String message = fallbackMessage ?? 'Произошла неожиданная ошибка';
    
    // Log error for debugging (in development mode)
    debugPrint('Error handled by ErrorService: $error');
    
    if (error.toString().contains('FormatException')) {
      message = 'Получены некорректные данные от сервера';
    } else if (error.toString().contains('TimeoutException')) {
      message = 'Превышено время ожидания ответа сервера';
    }
    
    showErrorToast(message);
  }

  /// Show retry prompt with action
  static void showRetryPrompt(String message, VoidCallback onRetry) {
    // For now, just show the error toast
    // In a full implementation, you might want to use a custom dialog
    showErrorToast('$message Потяните экран вниз для повтора.');
  }

  /// Validate and show appropriate auth error
  static void validateTelegramAuthResponse(Map<String, dynamic>? response) {
    if (response == null) {
      handleTelegramAuthError('Не получен ответ от сервера авторизации');
      return;
    }
    
    if (response.containsKey('error')) {
      handleTelegramAuthError(response['error']);
      return;
    }
    
    if (!response.containsKey('url') || !response.containsKey('token')) {
      handleTelegramAuthError('Получен некорректный ответ от сервера');
      return;
    }
  }

  /// Show loading indicator dismiss helper
  static void dismissLoadingWithError(String error) {
    // Helper to dismiss loading states and show error
    showErrorToast(error);
  }
}
