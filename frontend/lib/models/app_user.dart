class AppUser {
  final int id;
  final String email;
  final String username;
  final String role; // 'creator' | 'fan' | 'enterprise'
  final String phoneNumber;
  final bool twoFaEnabled;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.phoneNumber = '',
    this.twoFaEnabled = true,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        phoneNumber: (json['phone_number'] as String?) ?? '',
        twoFaEnabled: (json['two_fa_enabled'] as bool?) ?? true,
      );

  bool get isCreator => role == 'creator';
  bool get isEnterprise => role == 'enterprise';

  AppUser copyWith({bool? twoFaEnabled}) => AppUser(
        id: id,
        email: email,
        username: username,
        role: role,
        phoneNumber: phoneNumber,
        twoFaEnabled: twoFaEnabled ?? this.twoFaEnabled,
      );
}
