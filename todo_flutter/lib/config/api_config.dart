import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String devBaseUrl = 'http://localhost:5000/api';
  static const String prodBaseUrl =
      'https://flutter-node-app.onrender.com';

  static String get baseUrl {
    // This part is good for overriding with --dart-define
    const apiUrl = String.fromEnvironment('API_BASE_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }

    // Use kReleaseMode for a reliable, cross-platform check
    return kReleaseMode ? prodBaseUrl : devBaseUrl;
  }
}