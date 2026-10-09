enum Role {
  reader(1),
  librarian(2),
  admin(3);

  final int level;
  const Role(this.level);

  factory Role.fromString(String roleData) {
    final s = roleData.toLowerCase();
    if (s.contains('admin') || s.contains('3')) return Role.admin;
    if (s.contains('librarian') || s.contains('2')) return Role.librarian;
    return Role.reader;
  }
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? readerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.readerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawRole = json['role'] ?? json['roles'] ?? json['roleName'] ?? 'reader';

    return AppUser(
      id: json['id'] as int? ?? 0,
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: Role.fromString(rawRole.toString()),
      readerId: json['readerId'] as int?,
    );
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      expiresIn: json['expiresIn'] as int? ?? 0,
      user: json['user'] != null 
          ? AppUser.fromJson(json['user'] as Map<String, dynamic>)
          : const AppUser(id: 0, username: '', fullName: 'Неизвестно', email: '', role: Role.reader),
    );
  }
}