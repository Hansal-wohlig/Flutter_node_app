class ApiConfig {
  static const String devBaseUrl = 'http://localhost:5000/api';
  static const String prodBaseUrl =
      'https://flutter-node-app.onrender.com';

  static String get baseUrl {
    const apiUrl = String.fromEnvironment('API_BASE_URL');
    if (apiUrl.isNotEmpty) {
      return apiUrl;
    }

    // Default to production URL for release builds
    const bool isRelease = bool.fromEnvironment('dart.vm.product');
    return isRelease ? prodBaseUrl : devBaseUrl;
  }
}
