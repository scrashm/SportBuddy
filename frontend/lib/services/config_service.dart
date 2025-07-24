import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigService {
  static String get baseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'sportbuddy-production.up.railway.app';
  }

  static Future<void> initialize() async {
    await dotenv.load();
  }
}
