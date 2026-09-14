class ClassBooking {
  final String id;
  final String classScheduleId;
  final String memberId;
  final String memberName;
  final DateTime classDate; // tanggal spesifik kejadian kelas (bukan berulang)
  final DateTime createdAt;

  const ClassBooking({
    required this.id,
    required this.classScheduleId,
    required this.memberId,
    required this.memberName,
    required this.classDate,
    required this.createdAt,
  });

  factory ClassBooking.fromMap(Map<String, dynamic> map) {
    return ClassBooking(
      id: map['id'] as String,
      classScheduleId: map['class_schedule_id'] as String,
      memberId: map['member_id'] as String,
      memberName: map['member_name'] as String,
      classDate: DateTime.parse(map['class_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
