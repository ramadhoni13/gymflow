enum MembershipStatus { active, expiringSoon, expired }

class Member {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final DateTime joinDate;
  final String packageName;
  final DateTime membershipEndDate;
  final String? notes;
  final String? pin;

  const Member({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.joinDate,
    required this.packageName,
    required this.membershipEndDate,
    this.notes,
    this.pin,
  });

  MembershipStatus get status {
    final daysLeft = membershipEndDate.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return MembershipStatus.expired;
    if (daysLeft <= 7) return MembershipStatus.expiringSoon;
    return MembershipStatus.active;
  }

  factory Member.fromMap(Map<String, dynamic> map) {
    return Member(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String?,
      joinDate: DateTime.parse(map['join_date'] as String),
      packageName: map['package_name'] as String,
      membershipEndDate: DateTime.parse(map['membership_end_date'] as String),
      notes: map['notes'] as String?,
      pin: map['pin'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'join_date': joinDate.toIso8601String(),
      'package_name': packageName,
      'membership_end_date': membershipEndDate.toIso8601String(),
      'notes': notes,
      'pin': pin,
    };
  }

  Member copyWith({
    String? name,
    String? phone,
    String? email,
    DateTime? joinDate,
    String? packageName,
    DateTime? membershipEndDate,
    String? notes,
    String? pin,
  }) {
    return Member(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      joinDate: joinDate ?? this.joinDate,
      packageName: packageName ?? this.packageName,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      notes: notes ?? this.notes,
      pin: pin ?? this.pin,
    );
  }
}
