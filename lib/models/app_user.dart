import '../core/constants/enums.dart';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.password = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String password;
  final bool active;

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    UserRole? role,
    bool? active,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      active: active ?? this.active,
    );
  }
}
