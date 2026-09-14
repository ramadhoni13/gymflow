class CheckIn {
  final String id;
  final String memberId;
  final String memberName;
  final DateTime checkedInAt;
  final String? notes;

  const CheckIn({
    required this.id,
    required this.memberId,
    required this.memberName,
    required this.checkedInAt,
    this.notes,
  });

  factory CheckIn.fromMap(Map<String, dynamic> map) {
    return CheckIn(
      id: map['id'] as String,
      memberId: map['member_id'] as String,
      // member_name disimpan sebagai snapshot saat check-in dibuat (lihat
      // CheckinRepository.addCheckIn), bukan lewat join — supaya kompatibel
      // dengan realtime stream Supabase yang tidak mendukung embedded resource.
      memberName: map['member_name'] as String,
      // .toLocal() supaya jam yang ditampilkan sesuai zona waktu perangkat
      // (Supabase menyimpan & mengirim waktu dalam UTC).
      checkedInAt: DateTime.parse(map['checked_in_at'] as String).toLocal(),
      notes: map['notes'] as String?,
    );
  }
}
