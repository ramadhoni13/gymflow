import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/gym_settings.dart';

class GymSettingsRepository {
  final SupabaseClient _client = SupabaseService.client;
  static const _table = 'gym_settings';

  /// Stream baris tunggal pengaturan gym (id selalu = 1).
  Stream<GymSettings> watchSettings() {
    return _client
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', 1)
        .map((rows) => rows.isEmpty
            ? const GymSettings(gymName: '')
            : GymSettings.fromMap(rows.first));
  }

  Future<void> saveSettings(GymSettings settings) async {
    await _client.from(_table).update(settings.toMap()).eq('id', 1);
  }
}
