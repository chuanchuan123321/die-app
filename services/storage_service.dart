import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

class StorageService {
  static const String _emergencyEmailKey = 'emergency_email';
  static const String _lastCheckInKey = 'last_check_in';
  static const String _smtpHostKey = 'smtp_host';
  static const String _smtpPortKey = 'smtp_port';
  static const String _smtpUsernameKey = 'smtp_username';
  static const String _smtpPasswordKey = 'smtp_password';
  static const String _smtpFromNameKey = 'smtp_from_name';
  static const String _authTokenKey = 'auth_token';
  static const String _deviceIdKey = 'device_id';

  static SharedPreferences? _prefs;
  static String? _cachedDeviceId;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await getDeviceId();
  }

  // 设备ID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    final savedDeviceId = _prefs!.getString(_deviceIdKey);
    if (savedDeviceId != null) {
      _cachedDeviceId = savedDeviceId;
      return savedDeviceId;
    }

    // 生成新的设备ID
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    _cachedDeviceId = androidInfo.id;
    await _prefs!.setString(_deviceIdKey, _cachedDeviceId!);
    return _cachedDeviceId!;
  }

  // 认证Token
  static Future<void> setAuthToken(String token) async {
    await _prefs!.setString(_authTokenKey, token);
  }

  static Future<String?> getAuthToken() async {
    return _prefs!.getString(_authTokenKey);
  }

  static Future<void> removeAuthToken() async {
    await _prefs!.remove(_authTokenKey);
  }

  // 紧急联系人邮箱
  static Future<void> setEmergencyEmail(String email) async {
    await _prefs!.setString(_emergencyEmailKey, email);
  }

  static String? getEmergencyEmail() {
    return _prefs!.getString(_emergencyEmailKey);
  }

  // 最后签到时间
  static Future<void> setLastCheckIn(DateTime dateTime) async {
    await _prefs!.setString(_lastCheckInKey, dateTime.toIso8601String());
  }

  static DateTime? getLastCheckIn() {
    final dateString = _prefs!.getString(_lastCheckInKey);
    if (dateString == null) return null;
    return DateTime.parse(dateString);
  }

  static String getLastCheckInFormatted() {
    final lastCheckIn = getLastCheckIn();
    if (lastCheckIn == null) return '从未签到';
    return DateFormat('yyyy-MM-dd HH:mm').format(lastCheckIn);
  }

  // SMTP配置
  static Future<void> setSmtpConfig({
    required String host,
    required int port,
    required String username,
    required String password,
    required String fromName,
  }) async {
    await _prefs!.setString(_smtpHostKey, host);
    await _prefs!.setInt(_smtpPortKey, port);
    await _prefs!.setString(_smtpUsernameKey, username);
    await _prefs!.setString(_smtpPasswordKey, password);
    await _prefs!.setString(_smtpFromNameKey, fromName);
  }

  static Map<String, dynamic>? getSmtpConfig() {
    final host = _prefs!.getString(_smtpHostKey);
    final port = _prefs!.getInt(_smtpPortKey);
    final username = _prefs!.getString(_smtpUsernameKey);
    final password = _prefs!.getString(_smtpPasswordKey);
    final fromName = _prefs!.getString(_smtpFromNameKey);

    if (host == null ||
        port == null ||
        username == null ||
        password == null ||
        fromName == null) {
      return null;
    }

    return {
      'host': host,
      'port': port,
      'username': username,
      'password': password,
      'fromName': fromName,
    };
  }

  // 检查是否已配置
  static bool isConfigured() {
    return getEmergencyEmail() != null && getSmtpConfig() != null;
  }

  // 清除所有数据
  static Future<void> clearAll() async {
    await _prefs!.clear();
  }
}
