class AppConfig {
  /// API服务器地址
  ///
  /// 开发环境（模拟器）: http://10.0.2.2:3000/api
  /// 开发环境（真机）: http://YOUR_LOCAL_IP:3000/api
  /// 生产环境（服务器）: http://YOUR_SERVER_IP:3000/api 或 https://your-domain.com/api
  ///
  /// 修改方法：
  /// 1. 直接修改下面的默认值
  /// 2. 或构建时使用: flutter build apk --dart-define=API_BASE_URL=your_url
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // 👈 修改这里为您的服务器地址
  );

  /// 是否使用HTTPS
  static bool get isHttps => apiBaseUrl.startsWith('https://');

  /// 服务器地址（不含/api路径）
  static String get serverUrl {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }
}
