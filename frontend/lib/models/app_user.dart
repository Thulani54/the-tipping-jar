class AppUser {
  final int id;
  final String email;
  final String username;
  final String role; // 'creator' | 'fan' | 'enterprise'
  final String phoneNumber;
  final bool twoFaEnabled;
  final String gender;        // 'male' | 'female' | 'non_binary' | 'prefer_not_to_say' | ''
  final String? dateOfBirth;  // 'YYYY-MM-DD' or null
  final String bio;

  const AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.phoneNumber = '',
    this.twoFaEnabled = true,
    this.gender = '',
    this.dateOfBirth,
    this.bio = '',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        role: json['role'] as String,
        phoneNumber: (json['phone_number'] as String?) ?? '',
        twoFaEnabled: (json['two_fa_enabled'] as bool?) ?? true,
        gender: (json['gender'] as String?) ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        bio: (json['bio'] as String?) ?? '',
      );

  bool get isCreator => role == 'creator';
  bool get isEnterprise => role == 'enterprise';

  AppUser copyWith({bool? twoFaEnabled, String? gender, String? dateOfBirth, String? bio}) => AppUser(
        id: id,
        email: email,
        username: username,
        role: role,
        phoneNumber: phoneNumber,
        twoFaEnabled: twoFaEnabled ?? this.twoFaEnabled,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        bio: bio ?? this.bio,
      );
}
