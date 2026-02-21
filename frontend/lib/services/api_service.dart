import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_key_model.dart';
import '../models/app_user.dart';
import '../models/dispute_model.dart';
import '../models/creator.dart';
import '../models/creator_profile_model.dart';
import '../models/dashboard_stats.dart';
import '../models/enterprise_model.dart';
import '../models/jar_model.dart';
import '../models/tip.dart';
import '../models/tip_model.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api';

  /// JWT Bearer token (from login / session).
  final String? authToken;

  /// TippingJar API key (`tj_live_sk_v1_...`).
  /// When set, this is sent as `X-API-Key` on every request
  /// in addition to (or instead of) the JWT Bearer token.
  final String? apiKey;

  ApiService({this.authToken, this.apiKey});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
        if (apiKey != null) 'X-API-Key': apiKey!,
      };

  // ── API Key management ───────────────────────────────────────────

  /// List the authenticated user's active API keys.
  Future<List<ApiKeyModel>> getApiKeys() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/users/api-keys/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => ApiKeyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load API keys');
  }

  /// Create a new API key. The returned model contains `rawKey` — shown once.
  Future<ApiKeyModel> createApiKey(String name) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/api-keys/'),
      headers: _headers,
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode == 201) {
      return ApiKeyModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create API key: ${res.body}');
  }

  /// Revoke (soft-delete) an API key by ID.
  Future<void> revokeApiKey(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/users/api-keys/$id/'),
      headers: _headers,
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Failed to revoke API key');
    }
  }

  // ── Auth ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/token/'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Login failed: ${res.body}');
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/register/'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      }),
    );
    if (res.statusCode == 201) {
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Registration failed: ${res.body}');
  }

  Future<AppUser> getMe() async {
    final res = await http.get(Uri.parse('$_baseUrl/users/me/'), headers: _headers);
    if (res.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to fetch user profile');
  }

  Future<String> refreshToken(String refresh) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/token/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['access'] as String;
    }
    throw Exception('Token refresh failed');
  }

  // ── Creator dashboard ─────────────────────────────────────────────

  Future<CreatorProfileModel> getMyCreatorProfile() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/me/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return CreatorProfileModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load creator profile');
  }

  Future<CreatorProfileModel> updateMyCreatorProfile(
      Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/creators/me/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return CreatorProfileModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update profile: ${res.body}');
  }

  Future<DashboardStats> getDashboardStats() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/me/stats/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return DashboardStats.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load dashboard stats');
  }

  Future<List<TipModel>> getMyTips() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tips/me/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['results'] as List)
          .map((e) => TipModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load tips');
  }

  /// Tips sent BY the authenticated fan.
  Future<List<TipModel>> getSentTips() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tips/sent/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      // Handle both paginated and plain list responses
      final list = body is Map ? (body['results'] as List) : body as List;
      return list
          .map((e) => TipModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load sent tips');
  }

  // ── Jars (creator-owned) ──────────────────────────────────────────

  Future<List<JarModel>> getMyJars() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/jars/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? body['results']) : body as List;
      return (list as List).map((e) => JarModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load jars');
  }

  Future<JarModel> createJar({required String name, String description = '', double? goal}) async {
    final body = <String, dynamic>{'name': name, 'description': description};
    if (goal != null) body['goal'] = goal;
    final res = await http.post(
      Uri.parse('$_baseUrl/creators/me/jars/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) return JarModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    throw Exception('Failed to create jar: ${res.body}');
  }

  Future<JarModel> updateJar(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/creators/me/jars/$id/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) return JarModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    throw Exception('Failed to update jar: ${res.body}');
  }

  Future<void> deleteJar(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/creators/me/jars/$id/'), headers: _headers);
    if (res.statusCode != 204) throw Exception('Failed to delete jar');
  }

  Future<List<JarModel>> getCreatorJars(String creatorSlug) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorSlug/jars/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return (list as List).map((e) => JarModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load creator jars');
  }

  Future<JarModel> getPublicJar(String creatorSlug, String jarSlug) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/creators/$creatorSlug/jars/$jarSlug/'), headers: _headers);
    if (res.statusCode == 200) return JarModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    throw Exception('Jar not found');
  }

  // ── Public creators / tips ────────────────────────────────────────

  Future<List<Creator>> getCreators() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/'), headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['results'] as List).map((e) => Creator.fromJson(e)).toList();
    }
    throw Exception('Failed to load creators');
  }

  Future<Creator> getCreator(String slug) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/creators/$slug/'), headers: _headers);
    if (res.statusCode == 200) return Creator.fromJson(jsonDecode(res.body));
    throw Exception('Creator not found');
  }

  Future<List<Tip>> getCreatorTips(String slug) async {
    final res = await http.get(
        Uri.parse('$_baseUrl/tips/$slug/'), headers: _headers);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['results'] as List).map((e) => Tip.fromJson(e)).toList();
    }
    throw Exception('Failed to load tips');
  }

  // ── Contact & Disputes ────────────────────────────────────────────

  Future<Map<String, dynamic>> submitContact({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/support/contact/'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'subject': subject, 'message': message}),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to send message: ${res.body}');
  }

  Future<Map<String, dynamic>> fileDispute({
    required String name,
    required String email,
    required String reason,
    required String description,
    String tipRef = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/support/disputes/'),
      headers: _headers,
      body: jsonEncode({
        'name': name, 'email': email,
        'reason': reason, 'description': description,
        'tip_ref': tipRef,
      }),
    );
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to file dispute: ${res.body}');
  }

  Future<DisputeModel> getDisputeByToken(String token) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/support/disputes/$token/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return DisputeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Dispute not found');
  }

  Future<Map<String, dynamic>> initiateTip({
    required String creatorSlug,
    required double amount,
    required String tipperName,
    String tipperEmail = '',
    String message = '',
    int? jarId,
  }) async {
    final body = <String, dynamic>{
      'creator_slug': creatorSlug,
      'amount': amount,
      'tipper_name': tipperName,
      if (tipperEmail.isNotEmpty) 'tipper_email': tipperEmail,
      'message': message,
      if (jarId != null) 'jar_id': jarId,
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/tips/initiate/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to initiate tip: ${res.body}');
  }

  /// Verify a tip's payment status via Paystack.
  Future<Map<String, dynamic>> verifyTip(String reference) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tips/verify/$reference/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to verify tip: ${res.body}');
  }

  // ── Enterprise ────────────────────────────────────────────────────

  Future<EnterpriseModel> getMyEnterprise() async {
    final res = await http.get(Uri.parse('$_baseUrl/enterprise/me/'), headers: _headers);
    if (res.statusCode == 200) {
      return EnterpriseModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('No enterprise account found');
  }

  Future<EnterpriseModel> createEnterprise(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/enterprise/me/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return EnterpriseModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create enterprise: ${res.body}');
  }

  Future<List<EnterpriseMember>> getEnterpriseMembers() async {
    final res = await http.get(Uri.parse('$_baseUrl/enterprise/me/members/'), headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => EnterpriseMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load enterprise members');
  }

  Future<EnterpriseMember> addEnterpriseMember(String creatorSlug) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/enterprise/me/members/'),
      headers: _headers,
      body: jsonEncode({'creator_slug': creatorSlug}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return EnterpriseMember.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to add member: ${res.body}');
  }

  Future<void> removeEnterpriseMember(int membershipId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/enterprise/me/members/$membershipId/'),
      headers: _headers,
    );
    if (res.statusCode != 204) throw Exception('Failed to remove member');
  }

  Future<EnterpriseStats> getEnterpriseStats() async {
    final res = await http.get(Uri.parse('$_baseUrl/enterprise/me/stats/'), headers: _headers);
    if (res.statusCode == 200) {
      return EnterpriseStats.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load enterprise stats');
  }

  Future<List<FundDistribution>> getEnterpriseDistributions() async {
    final res = await http.get(Uri.parse('$_baseUrl/enterprise/me/distributions/'), headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => FundDistribution.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load distributions');
  }

  Future<FundDistribution> createDistribution({
    required String notes,
    required List<Map<String, dynamic>> items,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/enterprise/me/distributions/'),
      headers: _headers,
      body: jsonEncode({'notes': notes, 'items': items}),
    );
    if (res.statusCode == 201) {
      return FundDistribution.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create distribution: ${res.body}');
  }
}
