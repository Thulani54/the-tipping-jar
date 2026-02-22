import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _loading = false;
  bool _otpVerified = false;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get isCreator => _user?.isCreator ?? false;
  bool get isEnterprise => _user?.role == 'enterprise';
  bool get otpVerified => _otpVerified;
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
        // Persistent session — skip OTP on reload
        _otpVerified = true;
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
      if (_user!.twoFaEnabled) {
        _otpVerified = false;
        // Trigger OTP — errors are non-fatal (user can resend on OTP screen)
        try {
          await api.requestOtp();
        } catch (_) {}
      } else {
        // 2FA disabled — skip OTP screen entirely
        _otpVerified = true;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────
  Future<void> verifyOtp(String code) async {
    await api.verifyOtp(code);
    _otpVerified = true;
    notifyListeners();
  }

  // ── Register (creates account; does NOT log in automatically) ─────
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String phoneNumber = '',
  }) async {
    _loading = true;
    notifyListeners();
    try {
      return await ApiService().register(
        username: username,
        email: email,
        password: password,
        role: role,
        phoneNumber: phoneNumber,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ── Toggle 2FA ────────────────────────────────────────────────────
  Future<void> setTwoFa(bool enabled) async {
    await api.updateUserProfile({'two_fa_enabled': enabled});
    _user = _user?.copyWith(twoFaEnabled: enabled);
    notifyListeners();
  }

  // ── Logout ────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _otpVerified = false;
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
