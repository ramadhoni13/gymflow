enum UserRole { owner, admin, staf }

extension UserRoleX on UserRole {
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'admin':
        return UserRole.admin;
      case 'staf':
      case 'staff':
        return UserRole.staf;
      default:
        throw ArgumentError('Role tidak dikenal: $value');
    }
  }

  String get label {
    switch (this) {
      case UserRole.owner:
        return 'Owner';
      case UserRole.admin:
        return 'Admin';
      case UserRole.staf:
        return 'Staf';
    }
  }

  /// Dipakai untuk cek akses di route guard & UI (tampil/sembunyikan menu).
  /// Aturan sebenarnya tetap harus ditegakkan juga lewat RLS di Supabase.
  bool canAccess(String featureKey) {
    const ownerOnly = {'staff_management', 'reports_financial', 'gym_settings'};
    const adminAndUp = {'members', 'packages', 'payments', 'classes_schedule', 'reports_operational'};
    const stafAndUp = {'checkin', 'classes_view'};

    switch (this) {
      case UserRole.owner:
        return true; // owner akses semua
      case UserRole.admin:
        return adminAndUp.contains(featureKey) || stafAndUp.contains(featureKey);
      case UserRole.staf:
        return stafAndUp.contains(featureKey);
    }
  }
}

class AppUser {
  final String id;
  final String email;
  final String name;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String,
      name: map['name'] as String? ?? '',
      role: UserRoleX.fromString(map['role'] as String),
    );
  }
}
