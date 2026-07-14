import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  String? _error;
  String _role = 'customer';
  Map<String, dynamic>? _profile;
  bool _initialized = false;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    if (AuthService.isLoggedIn) {
      await _loadRole();
    }
    _initialized = true;
    notifyListeners();
  }

  bool get loading => _loading;
  String? get error => _error;
  String get role => _role;
  bool get isAdmin => _role == 'admin';
  Map<String, dynamic>? get profile => _profile;
  bool get isLoggedIn => AuthService.isLoggedIn;
  bool get initialized => _initialized;

  Future<bool> signUp(String email, String password, String fullName) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await AuthService.signUp(
        email: email, password: password, fullName: fullName);
    _loading = false;
    if (!res['success']) {
      _error = res['message'];
      notifyListeners();
      return false;
    }
    await _loadRole();
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    final res = await AuthService.login(email: email, password: password);
    _loading = false;
    if (!res['success']) {
      _error = res['message'];
      notifyListeners();
      return false;
    }
    await _loadRole();
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await AuthService.logout();
    _role = 'customer';
    _profile = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _loadRole() async {
    _role = await AuthService.getUserRole();
    _profile = await AuthService.getProfile();
  }

  Future<void> refreshProfile() async {
    await _loadRole();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
