import 'dart:async';
import 'dart:convert';

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
  bool _initialized = false;
  String? _otpSendError;
  Timer? _refreshTimer;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _user != null;
  bool get isCreator => _user?.isCreator ?? false;
  bool get isEnterprise => _user?.role == 'enterprise';
  bool get isAdmin => _user?.role == 'admin';
  bool get otpVerified => _otpVerified;
  bool get loading => _loading;
  bool get isInitialized => _initialized;
  String? get otpSendError => _otpSendError;

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
        _scheduleRefresh(_accessToken!);
      } catch (_) {
        await _tryRefresh();
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // ── Login ─────────────────────────────────────────────────────────
  Future<void> login(String email, String password) async {
    _loading = true;
    notifyListeners();
    try {
      final data = await ApiService().login(email, password);
      _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      final access  = data['access']  as String;
      final refresh = data['refresh'] as String;
      await _saveTokens(access, refresh);
      _scheduleRefresh(access);
      if (_user!.twoFaEnabled) {
        _otpVerified = false;
        _otpSendError = null;
        try {
          await api.requestOtp();
        } catch (e) {
          // Store error so the OTP screen can surface it — user can still resend
          _otpSendError = e.toString().replaceFirst('Exception: ', '');
        }
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
    _otpSendError = null;
    notifyListeners();
  }

  // ── Register (creates account; does NOT log in automatically) ─────
  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String phoneNumber = '',
    String firstName = '',
    String lastName = '',
    String referralCode = '',
    bool isMinor = false,
    String guardianName = '',
    String guardianEmail = '',
    String guardianPhone = '',
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
        firstName: firstName,
        lastName: lastName,
        referralCode: referralCode,
        isMinor: isMinor,
        guardianName: guardianName,
        guardianEmail: guardianEmail,
        guardianPhone: guardianPhone,
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
    _refreshTimer?.cancel();
    _refreshTimer = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    _otpVerified = false;
    _otpSendError = null;
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
      // Restored session via refresh — skip OTP just like the direct init() path
      _otpVerified = true;
      _scheduleRefresh(newAccess);
      notifyListeners();
    } catch (_) {
      // Refresh also failed — clear everything and boot to login
      await logout();
    }
  }

  // ── Proactive token refresh ───────────────────────────────────────
  // Decodes the JWT expiry claim and schedules a refresh 60 seconds before
  // the access token expires, so in-flight requests never hit a 401.

  void _scheduleRefresh(String token) {
    _refreshTimer?.cancel();

    final expiry = _jwtExpiry(token);
    if (expiry == null) {
      // Can't decode expiry — fall back to refreshing after 55 minutes
      // (backend access token lifetime is 1 hour)
      _refreshTimer = Timer(const Duration(minutes: 55), _tryRefresh);
      return;
    }

    final now     = DateTime.now();
    final cushion = const Duration(seconds: 60);
    final delay   = expiry.subtract(cushion).difference(now);

    if (delay <= Duration.zero) {
      // Already expired (or within the cushion) — refresh immediately
      _tryRefresh();
      return;
    }

    _refreshTimer = Timer(delay, _tryRefresh);
  }

  /// Decodes the `exp` claim from a JWT without verifying the signature.
  DateTime? _jwtExpiry(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // JWT uses base64url; pad to a multiple of 4
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final data    = jsonDecode(utf8.decode(payload)) as Map<String, dynamic>;
      final exp     = data['exp'];
      if (exp == null) return null;
      return DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
