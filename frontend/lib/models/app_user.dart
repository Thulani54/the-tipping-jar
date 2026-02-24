class AppUser {
  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
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
    this.firstName = '',
    this.lastName = '',
    required this.role,
    this.phoneNumber = '',
    this.twoFaEnabled = true,
    this.gender = '',
    this.dateOfBirth,
    this.bio = '',
  });

  /// Full display name: "First Last", falls back to username
  String get displayName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isNotEmpty ? full : username;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as int,
        email: json['email'] as String,
        username: json['username'] as String,
        firstName: (json['first_name'] as String?) ?? '',
        lastName: (json['last_name'] as String?) ?? '',
        role: json['role'] as String,
        phoneNumber: (json['phone_number'] as String?) ?? '',
        twoFaEnabled: (json['two_fa_enabled'] as bool?) ?? true,
        gender: (json['gender'] as String?) ?? '',
        dateOfBirth: json['date_of_birth'] as String?,
        bio: (json['bio'] as String?) ?? '',
      );

  bool get isCreator => role == 'creator';
  bool get isEnterprise => role == 'enterprise';

  AppUser copyWith({
    bool? twoFaEnabled, String? gender, String? dateOfBirth, String? bio,
    String? firstName, String? lastName,
  }) => AppUser(
        id: id,
        email: email,
        username: username,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        role: role,
        phoneNumber: phoneNumber,
        twoFaEnabled: twoFaEnabled ?? this.twoFaEnabled,
        gender: gender ?? this.gender,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        bio: bio ?? this.bio,
      );
}
