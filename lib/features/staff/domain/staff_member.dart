import '../../auth/domain/user_role.dart';

class StaffMember {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const StaffMember({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory StaffMember.fromMap(Map<String, dynamic> map) {
    return StaffMember(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String? ?? '',
      role: UserRoleX.fromString(map['role'] as String),
    );
  }
}
