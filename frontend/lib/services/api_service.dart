import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/creator.dart';
import '../models/tip.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api';

  final String? authToken;

  ApiService({this.authToken});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      };

  // ── Auth ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/token/'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Login failed: ${res.body}');
  }

  Future<Map<String, dynamic>> register({
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
    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception('Registration failed: ${res.body}');
  }

  // ── Creators ─────────────────────────────────────────────────────
  Future<List<Creator>> getCreators() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results.map((e) => Creator.fromJson(e)).toList();
    }
    throw Exception('Failed to load creators');
  }

  Future<Creator> getCreator(String slug) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/creators/$slug/'),
      headers: _headers,
    );
    if (res.statusCode == 200) return Creator.fromJson(jsonDecode(res.body));
    throw Exception('Creator not found');
  }

  // ── Tips ─────────────────────────────────────────────────────────
  Future<List<Tip>> getCreatorTips(String slug) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/tips/$slug/'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final results = data['results'] as List;
      return results.map((e) => Tip.fromJson(e)).toList();
    }
    throw Exception('Failed to load tips');
  }

  Future<String> initiateTip({
    required String creatorSlug,
    required double amount,
    required String tipperName,
    String message = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/tips/initiate/'),
      headers: _headers,
      body: jsonEncode({
        'creator_slug': creatorSlug,
        'amount': amount,
        'tipper_name': tipperName,
        'message': message,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['client_secret'] as String;
    }
    throw Exception('Failed to initiate tip: ${res.body}');
  }
}
