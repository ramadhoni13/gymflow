import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/class_schedule.dart';

class ClassScheduleRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'class_schedules';

  Stream<List<ClassSchedule>> watchClasses() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('start_time')
        .map((rows) => rows.map(ClassSchedule.fromMap).toList());
  }

  Future<ClassSchedule> addClass(ClassSchedule schedule) async {
    final data = await _client.from(_table).insert(schedule.toMap()).select().single();
    return ClassSchedule.fromMap(data);
  }

  Future<ClassSchedule> updateClass(ClassSchedule schedule) async {
    final data = await _client
        .from(_table)
        .update(schedule.toMap())
        .eq('id', schedule.id)
        .select()
        .single();
    return ClassSchedule.fromMap(data);
  }

  Future<void> deleteClass(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
