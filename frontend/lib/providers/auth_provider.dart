import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _loading = false;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get isCreator => _user?.isCreator ?? false;
  bool get loading => _loading;

  ApiService get api => ApiService(authToken: _accessToken);

  // ── Boot: restore session from disk ──────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');

    if (_accessToken != null) {
      try {
        // Restore full user profile. If the access token is expired, try refresh.
        _user = await ApiService(authToken: _accessToken).getMe();
      } catch (_) {
        await _tryRefresh();
      }
    }
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService().login(email, password);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await _saveTokens(data['access'] as String, data['refresh'] as String);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Register (creates account; does NOT log in automatically) ─────
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      return await ApiService().register(
        username: username,
        email: email,
        password: password,
        role: role,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    notifyListeners();
  }

  // ── Internals ─────────────────────────────────────────────────────
  Future<void> _saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    _accessToken = access;
    _refreshToken = refresh;
  }

  Future<void> _tryRefresh() async {
    if (_refreshToken == null) {
      await logout();
      return;
    }
    try {
      final newAccess = await ApiService().refreshToken(_refreshToken!);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', newAccess);
      _accessToken = newAccess;
      _user = await ApiService(authToken: _accessToken).getMe();
    } catch (_) {
      // Refresh also failed — clear everything
      await logout();
    }
  }
}
