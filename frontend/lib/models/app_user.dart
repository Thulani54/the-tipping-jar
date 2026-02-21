class AppUser {
  final int id;
  final String email;
  final String username;
  final String role; // 'creator' | 'fan'

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
      );

  bool get isCreator => role == 'creator';
}
