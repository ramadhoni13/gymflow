import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/class_booking.dart';

class BookingFullException implements Exception {
  final int capacity;
  BookingFullException(this.capacity);
  @override
  String toString() => 'Kelas sudah penuh (kapasitas $capacity)';
}

class AlreadyBookedException implements Exception {
  @override
  String toString() => 'Member ini sudah terdaftar di kelas ini pada tanggal yang sama';
}

class ClassBookingRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'class_bookings';

  /// Stream semua booking untuk satu jadwal kelas (lintas tanggal).
  /// Filter tanggal spesifik dilakukan di sisi client/provider.
  Stream<List<ClassBooking>> watchBookingsForClass(String classScheduleId) {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('class_schedule_id', classScheduleId)
        .order('created_at')
        .map((rows) => rows.map(ClassBooking.fromMap).toList());
  }

  Future<int> countBookings({required String classScheduleId, required DateTime classDate}) async {
    final dateStr = _dateOnly(classDate);
    final data = await _client
        .from(_table)
        .select('id')
        .eq('class_schedule_id', classScheduleId)
        .eq('class_date', dateStr);
    return (data as List).length;
  }

  Future<ClassBooking> addBooking({
    required String classScheduleId,
    required String memberId,
    required String memberName,
    required DateTime classDate,
    required int capacity,
  }) async {
    final dateStr = _dateOnly(classDate);

    final existing = await _client
        .from(_table)
        .select('id')
        .eq('class_schedule_id', classScheduleId)
        .eq('member_id', memberId)
        .eq('class_date', dateStr);
    if ((existing as List).isNotEmpty) {
      throw AlreadyBookedException();
    }

    final currentCount = await countBookings(classScheduleId: classScheduleId, classDate: classDate);
    if (currentCount >= capacity) {
      throw BookingFullException(capacity);
    }

    final data = await _client
        .from(_table)
        .insert({
          'class_schedule_id': classScheduleId,
          'member_id': memberId,
          'member_name': memberName,
          'class_date': dateStr,
          'created_by': _client.auth.currentUser?.id,
        })
        .select()
        .single();
    return ClassBooking.fromMap(data);
  }

  Future<void> cancelBooking(String id) async {
    // .select() setelah delete supaya kita bisa tahu apakah baris benar-benar
    // terhapus — Supabase tidak selalu memberi error kalau RLS menolak delete,
    // seringkali cuma "0 baris terpengaruh" tanpa exception sama sekali.
    final data = await _client.from(_table).delete().eq('id', id).select();
    if ((data as List).isEmpty) {
      throw Exception('Booking tidak ditemukan, atau kamu tidak punya izin membatalkannya');
    }
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
