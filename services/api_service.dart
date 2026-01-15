import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'storage_service.dart';

class ApiService {
  static String baseUrl = AppConfig.apiBaseUrl;
  static String? _token;

  static Future<void> init() async {
    _token = await StorageService.getAuthToken();
  }

  static Future<void> _saveToken(String? token) async {
    _token = token;
    if (token != null) {
      await StorageService.setAuthToken(token);
    } else {
      await StorageService.removeAuthToken();
    }
  }

  static Map<String, String> _getHeaders({bool requireAuth = true}) {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // 认证相关
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String deviceId,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(requireAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
          'deviceId': deviceId,
          'name': name,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '注册失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(requireAuth: false),
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '登录失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> loginDevice({
    required String deviceId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login-device'),
        headers: _getHeaders(requireAuth: false),
        body: jsonEncode({'deviceId': deviceId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _saveToken(data['token']);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '登录失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '获取失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateSmtpConfig({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/smtp'),
        headers: _getHeaders(),
        body: jsonEncode({
          'host': host,
          'port': port,
          'username': username,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '更新失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateEmergencyEmail({
    required String emergencyEmail,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/emergency-email'),
        headers: _getHeaders(),
        body: jsonEncode({'emergencyEmail': emergencyEmail}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '更新失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  // 签到相关
  static Future<Map<String, dynamic>> checkIn() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/checkin'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 同步更新本地存储
        await StorageService.setLastCheckIn(DateTime.now());
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '签到失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLastCheckIn() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkin/last'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['lastCheckin'] != null) {
          // 解析UTC时间并转换为本地时间
          final utcTime = DateTime.parse(data['lastCheckin']);
          await StorageService.setLastCheckIn(utcTime.toLocal());
        }
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '获取失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/checkin/stats'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '获取失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> sendTestEmail() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/test-email'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '发送失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  // 紧急联系人相关
  static Future<Map<String, dynamic>> getContacts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/contacts'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['contacts']};
      } else {
        return {'success': false, 'error': data['error'] ?? '获取失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> addContact({
    required String name,
    required String email,
    String? phone,
    bool isPrimary = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/contacts'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          if (phone != null) 'phone': phone,
          'isPrimary': isPrimary,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '添加失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateContact({
    required int id,
    required String name,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contacts/$id'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'email': email,
          if (phone != null) 'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '更新失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> deleteContact({required int id}) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/contacts/$id'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '删除失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> setPrimaryContact({required int id}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/contacts/$id/primary'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '设置失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  // 用户设置相关
  static Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/settings'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': data['error'] ?? '获取失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateSettings({
    int? alertThresholdMinutes,
    bool? enableEmailAlert,
    bool? enableSmsAlert,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/settings'),
        headers: _getHeaders(),
        body: jsonEncode({
          if (alertThresholdMinutes != null) 'alertThresholdMinutes': alertThresholdMinutes,
          if (enableEmailAlert != null) 'enableEmailAlert': enableEmailAlert,
          if (enableSmsAlert != null) 'enableSmsAlert': enableSmsAlert,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'error': data['error'] ?? '更新失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }

  static Future<void> logout() async {
    await _saveToken(null);
  }

  static bool get isLoggedIn => _token != null;

  // 删除账户
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/auth/account'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 删除成功后清除token
        await logout();
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'error': data['error'] ?? '删除失败'};
      }
    } catch (e) {
      return {'success': false, 'error': '网络错误: $e'};
    }
  }
}
