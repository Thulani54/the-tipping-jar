import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/api_key_model.dart';
import '../models/app_user.dart';
import '../models/blog_post_model.dart';
import '../models/commission_model.dart';
import '../models/creator_post_model.dart';
import '../models/dispute_model.dart';
import '../models/creator.dart';
import '../models/creator_profile_model.dart';
import '../models/dashboard_stats.dart';
import '../models/enterprise_model.dart';
import '../models/jar_model.dart';
import '../models/milestone_model.dart';
import '../models/pledge_model.dart';
import '../models/tier_model.dart';
import '../models/tip.dart';
import '../models/tip_model.dart';

class ApiService {
  static const String _baseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000') + '/api';

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

  /// Converts a DRF error response body into a single readable string.
  /// Handles: {"detail": "..."}, {"non_field_errors": [...]}, {"email": [...], ...}
  static String _parseApiError(String body, String fallback) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        if (data.containsKey('detail')) return data['detail'] as String;
        if (data.containsKey('non_field_errors')) {
          final errs = data['non_field_errors'] as List<dynamic>;
          return errs.map((e) => e.toString()).join(' ');
        }
        // Field errors — collect the first message per field
        const fieldLabels = {
          'email': 'Email', 'username': 'Username',
          'password': 'Password', 'phone_number': 'Phone',
        };
        final msgs = <String>[];
        data.forEach((field, errors) {
          if (errors is List && errors.isNotEmpty) {
            final label = fieldLabels[field] ?? field;
            msgs.add('$label: ${errors.first}');
          }
        });
        if (msgs.isNotEmpty) return msgs.join('\n');
      }
    } catch (_) {}
    return fallback;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/token/'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception(_parseApiError(res.body, 'Invalid email or password.'));
  }

  Future<AppUser> register({
    required String username,
    required String email,
    required String password,
    required String role,
    String phoneNumber = '',
    String firstName = '',
    String lastName = '',
  }) async {
    final body = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'role': role,
    };
    if (phoneNumber.isNotEmpty) body['phone_number'] = phoneNumber;
    if (firstName.isNotEmpty) body['first_name'] = firstName;
    if (lastName.isNotEmpty) body['last_name'] = lastName;
    final res = await http.post(
      Uri.parse('$_baseUrl/users/register/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 201) {
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(_parseApiError(res.body, 'Registration failed. Please try again.'));
  }

  /// Send a one-time verification code for new-user email/phone confirmation.
  /// Does not require 2FA to be enabled on the account.
  Future<void> sendRegistrationOtp({String method = 'email'}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/verify-registration/'),
      headers: _headers,
      body: jsonEncode({'method': method}),
    );
    if (res.statusCode != 200) {
      String detail = 'Failed to send verification code.';
      try {
        detail = (jsonDecode(res.body) as Map<String, dynamic>)['detail'] as String? ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }
  }

  /// Confirm the registration verification OTP.
  Future<void> confirmRegistrationOtp(String code) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/verify-registration/confirm/'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    if (res.statusCode != 200) {
      String detail = 'Invalid or expired code.';
      try {
        detail = (jsonDecode(res.body) as Map<String, dynamic>)['detail'] as String? ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }
  }

  Future<void> requestOtp({String method = 'email'}) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/otp/request/'),
      headers: _headers,
      body: jsonEncode({'method': method}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      String detail = 'Failed to send verification code.';
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        detail = body['detail'] as String? ?? detail;
      } catch (_) {}
      throw Exception(detail);
    }
  }

  Future<void> verifyOtp(String code) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/otp/verify/'),
      headers: _headers,
      body: jsonEncode({'code': code}),
    );
    if (res.statusCode == 200) return;
    throw Exception('Invalid or expired code');
  }

  Future<void> switchOtpToSms() async {
    await http.post(
      Uri.parse('$_baseUrl/users/otp/switch-method/'),
      headers: _headers,
      body: jsonEncode({'method': 'sms'}),
    );
  }

  Future<AppUser> updateUserProfile(Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/users/me/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update user profile: ${res.body}');
  }

  Future<void> deleteAccount(String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/users/me/delete/'),
      headers: _headers,
      body: jsonEncode({'password': password}),
    );
    if (res.statusCode == 200) return;
    final msg = (jsonDecode(res.body) as Map<String, dynamic>)['detail'] as String? ?? 'Failed to delete account';
    throw Exception(msg);
  }

  /// Upload (or replace) the authenticated user's avatar.
  /// Uses multipart PATCH so the server stores it as an image file.
  Future<void> updateAvatar(Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('PATCH', Uri.parse('$_baseUrl/users/me/'))
      ..headers.addAll(_authHeaders)
      ..files.add(http.MultipartFile.fromBytes('avatar', bytes, filename: filename));
    final streamed = await req.send();
    if (streamed.statusCode != 200) {
      throw Exception('Avatar upload failed (${streamed.statusCode})');
    }
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

  // ── KYC documents ─────────────────────────────────────────────────

  Future<List<KycDocumentModel>> getKycDocuments() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/kyc/'), headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => KycDocumentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load KYC documents');
  }

  Future<KycDocumentModel> uploadKycDocument(
      String docType, Uint8List bytes, String filename) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/creators/me/kyc/'))
      ..headers.addAll(_authHeaders)
      ..fields['doc_type'] = docType
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode == 201) {
      return KycDocumentModel.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw Exception('Upload failed (${streamed.statusCode}): $body');
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
      final List list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => JarModel.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<List<DisputeModel>> getMyDisputes() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/support/disputes/my/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => DisputeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load disputes');
  }

  Future<List<DisputeModel>> getEnterpriseDisputes() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/support/disputes/enterprise/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => DisputeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load enterprise disputes');
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

  // ── Creator posts ─────────────────────────────────────────────────

  Map<String, String> get _authHeaders => Map.fromEntries(
        _headers.entries.where((e) => e.key != 'Content-Type'));

  Future<List<CreatorPostModel>> getMyPosts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/me/posts/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list
          .map((e) => CreatorPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load posts');
  }

  Future<CreatorPostModel> createPost(
    Map<String, String> fields, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final req = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/creators/me/posts/'),
    )
      ..headers.addAll(_authHeaders)
      ..fields.addAll(fields);

    if (fileBytes != null && fileName != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'media_file',
        fileBytes,
        filename: fileName,
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 201) {
      return CreatorPostModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create post: ${res.body}');
  }

  Future<CreatorPostModel> updatePost(
    int id,
    Map<String, String> fields, {
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    final req = http.MultipartRequest(
      'PATCH',
      Uri.parse('$_baseUrl/creators/me/posts/$id/'),
    )
      ..headers.addAll(_authHeaders)
      ..fields.addAll(fields);

    if (fileBytes != null && fileName != null) {
      req.files.add(http.MultipartFile.fromBytes(
        'media_file',
        fileBytes,
        filename: fileName,
      ));
    }

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      return CreatorPostModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update post: ${res.body}');
  }

  Future<void> deletePost(int id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/creators/me/posts/$id/'),
      headers: _headers,
    );
    if (res.statusCode != 204) throw Exception('Failed to delete post');
  }

  Future<List<CreatorPostModel>> getPublicPosts(String slug) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/$slug/posts/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list
          .map((e) => CreatorPostModel.fromPublicJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load posts');
  }

  /// Returns full post list if email has a completed tip, throws on 403.
  Future<List<CreatorPostModel>> unlockPosts(String slug, String email) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/creators/$slug/posts/access/'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List)
          .map((e) => CreatorPostModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (res.statusCode == 403) {
      throw Exception('no_tip');
    }
    throw Exception('Failed to unlock posts: ${res.body}');
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

  // ── Pledges ───────────────────────────────────────────────────────

  Future<List<PledgeModel>> getMyPledges() async {
    final res = await http.get(Uri.parse('$_baseUrl/tips/pledges/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => PledgeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load pledges');
  }

  /// Public subscribe — works for both anonymous and logged-in fans.
  Future<Map<String, dynamic>> createPledge({
    required String creatorSlug,
    required double amount,
    int? tierId,
    String fanEmail = '',
    String fanName = '',
  }) async {
    final body = <String, dynamic>{
      'creator_slug': creatorSlug,
      'amount': amount,
      if (tierId != null) 'tier_id': tierId,
      if (fanEmail.isNotEmpty) 'fan_email': fanEmail,
      if (fanName.isNotEmpty) 'fan_name': fanName,
    };
    final res = await http.post(
      Uri.parse('$_baseUrl/tips/subscribe/'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception(_parseApiError(res.body, 'Failed to create subscription.'));
  }

  Future<PledgeModel> updatePledge(int id, String status) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/tips/pledges/$id/'),
      headers: _headers,
      body: jsonEncode({'status': status}),
    );
    if (res.statusCode == 200) {
      return PledgeModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update pledge: ${res.body}');
  }

  Future<List<PledgeModel>> getCreatorPledges() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/pledges/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => PledgeModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load creator pledges');
  }

  // ── Streaks ───────────────────────────────────────────────────────

  Future<List<TipStreakModel>> getMyStreaks() async {
    final res = await http.get(Uri.parse('$_baseUrl/tips/streaks/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => TipStreakModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load streaks');
  }

  // ── Tiers ─────────────────────────────────────────────────────────

  Future<List<TierModel>> getPublicTiers(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/$slug/tiers/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => TierModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load tiers');
  }

  Future<List<TierModel>> getMyTiers() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/tiers/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => TierModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load tiers');
  }

  Future<TierModel> createTier(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/creators/me/tiers/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return TierModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create tier: ${res.body}');
  }

  Future<TierModel> updateTier(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/creators/me/tiers/$id/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return TierModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update tier: ${res.body}');
  }

  Future<void> deleteTier(int id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/creators/me/tiers/$id/'), headers: _headers);
    if (res.statusCode != 204) throw Exception('Failed to delete tier');
  }

  // ── Milestones ────────────────────────────────────────────────────

  Future<List<MilestoneModel>> getPublicMilestones(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/$slug/milestones/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => MilestoneModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load milestones');
  }

  Future<List<MilestoneModel>> getMyMilestones() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/milestones/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => MilestoneModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load milestones');
  }

  Future<MilestoneModel> createMilestone(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/creators/me/milestones/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return MilestoneModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to create milestone: ${res.body}');
  }

  Future<MilestoneModel> updateMilestone(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/creators/me/milestones/$id/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return MilestoneModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update milestone: ${res.body}');
  }

  // ── Commissions ───────────────────────────────────────────────────

  Future<CommissionSlotModel> getMyCommissionSlot() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/commission-slot/'), headers: _headers);
    if (res.statusCode == 200) {
      return CommissionSlotModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to load commission slot');
  }

  Future<CommissionSlotModel> updateCommissionSlot(Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/creators/me/commission-slot/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return CommissionSlotModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update commission slot: ${res.body}');
  }

  Future<List<CommissionRequestModel>> getMyCommissions() async {
    final res = await http.get(Uri.parse('$_baseUrl/creators/me/commissions/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => CommissionRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load commissions');
  }

  Future<CommissionRequestModel> updateCommission(int id, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/creators/me/commissions/$id/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return CommissionRequestModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Failed to update commission: ${res.body}');
  }

  Future<void> submitCommissionRequest(String slug, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/creators/$slug/commission-requests/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Failed to submit commission request: ${res.body}');
    }
  }

  Future<CommissionSlotModel?> getPublicCommissionSlot(String slug) async {
    // Reuse the creator detail endpoint — slot info is not directly exposed publicly.
    // Instead, fetch creator commission slot via a dedicated check.
    // We call the creator-level commission-requests endpoint to check if open.
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/creators/$slug/commission-requests/'),
        headers: _headers,
      );
      // If the endpoint returns 400 "not accepting commissions", slot is closed.
      if (res.statusCode == 200 || res.statusCode == 201) return null;
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Enterprise document upload ────────────────────────────────────

  Future<void> uploadEnterpriseDocument(
    String docType,
    Uint8List bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_baseUrl/enterprise/me/documents/');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) request.headers['Authorization'] = 'Bearer $authToken';
    if (apiKey != null) request.headers['X-API-Key'] = apiKey!;
    request.fields['doc_type'] = docType;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Upload failed: $body');
    }
  }

  // ── Platform (Partner Program) ────────────────────────────────────

  Future<Map<String, dynamic>> applyForPlatform(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/platform/apply/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to submit application: ${res.body}');
  }

  Future<void> uploadPlatformDocument(
    int platformId,
    String docType,
    Uint8List bytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_baseUrl/platform/apply/$platformId/documents/');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) request.headers['Authorization'] = 'Bearer $authToken';
    if (apiKey != null) request.headers['X-API-Key'] = apiKey!;
    request.fields['doc_type'] = docType;
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await request.send();
    if (streamed.statusCode != 201) {
      final body = await streamed.stream.bytesToString();
      throw Exception('Upload failed: $body');
    }
  }

  // ── Admin portal ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse('$_baseUrl/admin/stats/'), headers: _headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to load admin stats');
  }

  Future<List<Map<String, dynamic>>> getAdminUsers({String? role, String? search}) async {
    final params = <String, String>{
      if (role != null) 'role': role,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$_baseUrl/admin/users/').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    throw Exception('Failed to load users');
  }

  Future<void> adminUpdateUser(int id, Map<String, dynamic> data) async {
    final res = await http.patch(Uri.parse('$_baseUrl/admin/users/$id/'),
        headers: _headers, body: jsonEncode(data));
    if (res.statusCode != 200) throw Exception('Failed to update user');
  }

  Future<List<Map<String, dynamic>>> getAdminTips({String? tipStatus, String? search}) async {
    final params = <String, String>{
      if (tipStatus != null) 'status': tipStatus,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$_baseUrl/admin/tips/').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    throw Exception('Failed to load tips');
  }

  Future<List<Map<String, dynamic>>> getAdminCreators({String? kycStatus, String? search}) async {
    final params = <String, String>{
      if (kycStatus != null) 'kyc_status': kycStatus,
      if (search != null && search.isNotEmpty) 'search': search,
    };
    final uri = Uri.parse('$_baseUrl/admin/creators/').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    throw Exception('Failed to load creators');
  }

  Future<void> adminKycApprove(int creatorId) async {
    final res = await http.post(
        Uri.parse('$_baseUrl/admin/creators/$creatorId/kyc/approve/'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to approve KYC');
  }

  Future<void> adminKycDecline(int creatorId, String reason) async {
    final res = await http.post(
        Uri.parse('$_baseUrl/admin/creators/$creatorId/kyc/decline/'),
        headers: _headers, body: jsonEncode({'reason': reason}));
    if (res.statusCode != 200) throw Exception('Failed to decline KYC');
  }

  Future<List<Map<String, dynamic>>> getAdminEnterprises({String? approvalStatus}) async {
    final params = <String, String>{
      if (approvalStatus != null) 'approval_status': approvalStatus,
    };
    final uri = Uri.parse('$_baseUrl/admin/enterprises/').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    throw Exception('Failed to load enterprises');
  }

  Future<void> adminEnterpriseApprove(int id) async {
    final res = await http.post(
        Uri.parse('$_baseUrl/admin/enterprises/$id/approve/'), headers: _headers);
    if (res.statusCode != 200) throw Exception('Failed to approve enterprise');
  }

  Future<void> adminEnterpriseReject(int id, String reason) async {
    final res = await http.post(
        Uri.parse('$_baseUrl/admin/enterprises/$id/reject/'),
        headers: _headers, body: jsonEncode({'reason': reason}));
    if (res.statusCode != 200) throw Exception('Failed to reject enterprise');
  }

  Future<List<Map<String, dynamic>>> getAdminBlogs() async {
    final res = await http.get(Uri.parse('$_baseUrl/admin/blog/'), headers: _headers);
    if (res.statusCode == 200) return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    throw Exception('Failed to load admin blog posts');
  }

  Future<Map<String, dynamic>> adminCreateBlog(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$_baseUrl/admin/blog/'),
        headers: _headers, body: jsonEncode(data));
    if (res.statusCode == 201) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to create blog post: ${res.body}');
  }

  Future<Map<String, dynamic>> adminUpdateBlog(String slug, Map<String, dynamic> data) async {
    final res = await http.patch(Uri.parse('$_baseUrl/admin/blog/$slug/'),
        headers: _headers, body: jsonEncode(data));
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Failed to update blog post: ${res.body}');
  }

  Future<void> adminDeleteBlog(String slug) async {
    final res = await http.delete(Uri.parse('$_baseUrl/admin/blog/$slug/'), headers: _headers);
    if (res.statusCode != 204) throw Exception('Failed to delete blog post');
  }

  // ── Blog ──────────────────────────────────────────────────────────

  /// Public list of published blog posts.
  Future<List<BlogPostModel>> getBlogs() async {
    final res = await http.get(Uri.parse('$_baseUrl/blog/'), headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      final list = body is Map ? (body['results'] as List? ?? []) : body as List;
      return list.map((e) => BlogPostModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load blog posts');
  }

  /// Full detail for a single published blog post by slug.
  Future<BlogPostModel> getBlog(String slug) async {
    final res = await http.get(Uri.parse('$_baseUrl/blog/$slug/'), headers: _headers);
    if (res.statusCode == 200) {
      return BlogPostModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Blog post not found');
  }

  // ── Creator notifications ──────────────────────────────────────────

  /// Fetch last 50 creator notifications.
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/me/notifications/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as List).cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Mark all unread notifications as read.
  Future<void> markNotificationsRead() async {
    await http.post(
      Uri.parse('$_baseUrl/creators/me/notifications/read/'),
      headers: _headers,
    );
  }
}
