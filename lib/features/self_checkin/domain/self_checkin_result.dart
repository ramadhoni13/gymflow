import '../../members/domain/member.dart';

class SelfCheckinResult {
  final String memberName;
  final String packageName;
  final DateTime membershipEndDate;
  final MembershipStatus status;

  const SelfCheckinResult({
    required this.memberName,
    required this.packageName,
    required this.membershipEndDate,
    required this.status,
  });

  factory SelfCheckinResult.fromMap(Map<String, dynamic> map) {
    MembershipStatus parseStatus(String s) {
      switch (s) {
        case 'expired':
          return MembershipStatus.expired;
        case 'expiring_soon':
          return MembershipStatus.expiringSoon;
        default:
          return MembershipStatus.active;
      }
    }

    return SelfCheckinResult(
      memberName: map['memberName'] as String,
      packageName: map['packageName'] as String,
      membershipEndDate: DateTime.parse(map['membershipEndDate'] as String),
      status: parseStatus(map['status'] as String),
    );
  }
}

class MemberNotFoundException implements Exception {
  final String message;
  MemberNotFoundException(this.message);
  @override
  String toString() => message;
}
