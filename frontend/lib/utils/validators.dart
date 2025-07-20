/// Вспомогательные функции-валидаторы
/// TODO: Добавить функции для валидации форм, email, паролей и т.д.
bool isValidEmail(String email) {
  // Простейшая проверка email
  return email.contains('@');
} 