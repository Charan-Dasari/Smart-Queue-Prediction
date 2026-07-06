import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class ApiService {
  static String get baseUrl {
    // If running on Web (browser), use localhost. If on a physical device, use localtunnel.
    if (kIsWeb) {
      return 'http://localhost:5164/api';
    }
    return 'https://solid-waves-agree.loca.lt/api';
  }

  static String? token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('jwt_token');
  }

  static Future<void> setToken(String tokenValue) async {
    token = tokenValue;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', tokenValue);
  }

  static Future<void> clearToken() async {
    token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Bypass-Tunnel-Reminder': 'true', // Required to bypass localtunnel warning
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'identifier': identifier, 
        'password': password,
        'isWeb': kIsWeb
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get profile');
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String mobile, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await setToken(data['token']);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> resetPasswordVerify(String name, String email, String mobile, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password-verify'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'mobile': mobile,
        'newPassword': newPassword
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reset password: ${response.body}');
    }
  }

  // ── Manual Onboarding ──
  static Future<Map<String, dynamic>> createProvider(String placeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/providers'),
      headers: _headers,
      body: jsonEncode({
        'placeId': placeId,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create provider: ${response.body}');
    }
  }

  static Future<void> deleteProvider(String providerId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/providers/$providerId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete provider: ${response.body}');
    }
  }

  // ── Providers ──
  static Future<List<dynamic>> getProviders({String? category, String? query}) async {
    String url = '$baseUrl/providers?';
    if (category != null && category.isNotEmpty && category != 'All') url += 'category=$category&';
    if (query != null && query.isNotEmpty) url += 'q=$query';

    final response = await http.get(Uri.parse(url), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load providers');
    }
  }

  // ── Places (Dataset-backed) ──
  static Future<Map<String, dynamic>> getPlaces({
    String? category,
    String? state,
    String? city,
    String? query,
    int page = 1,
    int pageSize = 50,
  }) async {
    final params = <String, String>{};
    if (category != null && category.isNotEmpty && category != 'All') params['category'] = category;
    if (state != null && state.isNotEmpty) params['state'] = state;
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (query != null && query.isNotEmpty) params['q'] = query;
    params['page'] = page.toString();
    params['pageSize'] = pageSize.toString();

    final uri = Uri.parse('$baseUrl/places').replace(queryParameters: params);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load places');
    }
  }

  static Future<List<String>> getPlaceStates() async {
    final response = await http.get(Uri.parse('$baseUrl/places/states'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    }
    throw Exception('Failed to fetch states');
  }

  static Future<List<String>> getPlaceCities({required String state}) async {
    final uri = Uri.parse('$baseUrl/places/cities').replace(queryParameters: {'state': state});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<String>();
    }
    throw Exception('Failed to fetch cities');
  }

  static Future<Map<String, dynamic>> getProviderById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/providers/$id'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('ProviderNotOnboarded');
    } else {
      throw Exception('Failed to get provider details');
    }
  }

  // ── Queues ──
  static Future<Map<String, dynamic>> joinQueue(String providerId, String serviceId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/queues/join'),
      headers: _headers,
      body: jsonEncode({
        'providerId': providerId,
        'serviceId': serviceId,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to join queue: ${response.body}');
    }
  }
  // ── Services ──
  static Future<List<dynamic>> getProviderServices(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/providers/$providerId/services'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load services');
    }
  }

  static Future<List<dynamic>> getProviderCountersById(String providerId) async {
    final response = await http.get(Uri.parse('$baseUrl/providers/$providerId/counters'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load provider counters');
    }
  }

  static Future<Map<String, dynamic>> createService(String providerId, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/providers/$providerId/services'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create service');
    }
  }

  static Future<Map<String, dynamic>> updateService(String serviceId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/services/$serviceId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update service');
    }
  }

  static Future<void> deleteService(String serviceId) async {
    final response = await http.delete(Uri.parse('$baseUrl/services/$serviceId'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete service');
    }
  }

  static Future<bool> toggleService(String serviceId) async {
    final response = await http.put(Uri.parse('$baseUrl/services/$serviceId/toggle'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['isActive'];
    } else {
      throw Exception('Failed to toggle service');
    }
  }
  
  static Future<List<dynamic>> getTimeSlots(String serviceId, String date) async {
    final response = await http.get(Uri.parse('$baseUrl/services/services/$serviceId/timeslots?date=$date'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load timeslots');
    }
  }

  // ── Staff ──
  static Future<List<dynamic>> getProviderStaff() async {
    final response = await http.get(Uri.parse('$baseUrl/staff/provider'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load staff');
    }
  }

  static Future<Map<String, dynamic>> createStaff(String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/staff'),
      headers: _headers,
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create staff');
    }
  }

  static Future<void> deleteStaff(String staffId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/staff/$staffId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete staff');
    }
  }

  static Future<void> assignCounter(String counterId, String? staffUserId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/counters/$counterId/assign'),
      headers: _headers,
      body: jsonEncode({
        'staffUserId': staffUserId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to assign counter');
    }
  }

  // ── Appointments ──
  static Future<List<dynamic>> getMyAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/appointments/my'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointments');
    }
  }

  static Future<Map<String, dynamic>> getAppointmentById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/appointments/$id'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load appointment details');
    }
  }

  static Future<List<dynamic>> getProviderAppointments() async {
    final response = await http.get(Uri.parse('$baseUrl/appointments/provider'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load provider appointments');
    }
  }

  static Future<Map<String, dynamic>> bookAppointment(String providerId, String serviceId, String? timeSlotId, DateTime date) async {
    final body = <String, dynamic>{
      'providerId': providerId,
      'serviceId': serviceId,
      'date': date.toIso8601String(),
    };
    if (timeSlotId != null) {
      body['timeSlotId'] = timeSlotId;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/appointments'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to book appointment: ${response.body}');
    }
  }

  // ── Queue ──
  static Future<Map<String, dynamic>?> getMyToken() async {
    final response = await http.get(Uri.parse('$baseUrl/queue/my-token'), headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['message'] != null) return null; // "No active token"
      return data;
    } else {
      throw Exception('Failed to get token');
    }
  }

  static Future<Map<String, dynamic>> getQueueTracking(String tokenId) async {
    final response = await http.get(Uri.parse('$baseUrl/queue/tracking/$tokenId'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to track queue');
    }
  }

  static Future<List<dynamic>> getProviderQueue() async {
    final response = await http.get(Uri.parse('$baseUrl/queue/provider'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load queue');
    }
  }



  // ── Dashboard ──
  static Future<Map<String, dynamic>> getUserDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/user'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }
  
  static Future<Map<String, dynamic>> getAdminDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/admin'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin dashboard');
    }
  }
  
  static Future<Map<String, dynamic>> getStaffDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/staff'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load staff dashboard');
    }
  }
  
  static Future<Map<String, dynamic>> getSuperAdminDashboard() async {
    final response = await http.get(Uri.parse('$baseUrl/dashboard/super-admin'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load super admin dashboard');
    }
  }
  
  // ── Notifications ──
  static Future<List<dynamic>> getNotifications() async {
    final response = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  static Future<void> markNotificationRead(String id) async {
    final response = await http.put(Uri.parse('$baseUrl/notifications/$id/read'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  static Future<void> markAllNotificationsRead() async {
    final response = await http.put(Uri.parse('$baseUrl/notifications/read-all'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  static Future<Map<String, dynamic>> updateProfile({String? name, String? email, String? mobile}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (mobile != null) body['mobile'] = mobile;

    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to change password: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>?> callNext() async {
    final response = await http.post(Uri.parse('$baseUrl/queue/call-next'), headers: _headers);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['message'] != null) return null; // No customers
      return json;
    } else {
      throw Exception('Failed to call next');
    }
  }

  static Future<void> completeToken(String tokenId) async {
    final response = await http.put(Uri.parse('$baseUrl/queue/$tokenId/complete'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to complete token');
    }
  }

  static Future<void> skipToken(String tokenId) async {
    final response = await http.put(Uri.parse('$baseUrl/queue/$tokenId/skip'), headers: _headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to skip token');
    }
  }

  // ── Counters ──
  static Future<List<dynamic>> getProviderCounters() async {
    final response = await http.get(Uri.parse('$baseUrl/counters/provider'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load counters');
    }
  }

  static Future<Map<String, dynamic>> createCounter(int number, String serviceName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/counters'),
      headers: _headers,
      body: jsonEncode({
        'number': number,
        'serviceName': serviceName,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create counter');
    }
  }

  static Future<void> deleteCounter(String counterId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/counters/$counterId'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete counter');
    }
  }

  static Future<void> updateCounterStatus(String counterId, int status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/counters/$counterId/status'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update counter status');
    }
  }

  // ── Roles ──
  static Future<List<dynamic>> getProviderUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/roles/users'), headers: _headers);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  static Future<void> updateUserRole(String userId, int role) async {
    final response = await http.put(
      Uri.parse('$baseUrl/roles/$userId'),
      headers: _headers,
      body: jsonEncode({'role': role}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update role: ${response.body}');
    }
  }
}
