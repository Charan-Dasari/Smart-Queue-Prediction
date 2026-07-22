import 'package:flutter/material.dart';
import 'package:intelliq/models/models.dart';
import 'api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    await ApiService.init();
    if (ApiService.token != null) {
      try {
        await _fetchProfile();
      } catch (e) {
        // Token might be expired or invalid
        await ApiService.clearToken();
      }
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchProfile() async {
    final data = await ApiService.getMe();
    _user = _parseUser(data);
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.login(identifier, password);
      _user = _parseUser(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String name, String email, String mobile, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.register(name, email, mobile, password);
      _user = _parseUser(data['user']);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPasswordVerify(String name, String email, String mobile, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.resetPasswordVerify(name, email, mobile, newPassword);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearToken();
    _user = null;
    notifyListeners();
  }

  AppUser _parseUser(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role'].toString().toLowerCase()) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'staff':
        role = UserRole.staff;
        break;
      case 'superadmin':
        role = UserRole.superAdmin;
        break;
      default:
        role = UserRole.user;
    }

    return AppUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'] ?? '',
      password: '', // Password is not sent back
      role: role,
      providerId: json['providerId'] ?? '',
    );
  }
}
