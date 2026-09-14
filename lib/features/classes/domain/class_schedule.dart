enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension DayOfWeekX on DayOfWeek {
  String get label {
    switch (this) {
      case DayOfWeek.monday:
        return 'Senin';
      case DayOfWeek.tuesday:
        return 'Selasa';
      case DayOfWeek.wednesday:
        return 'Rabu';
      case DayOfWeek.thursday:
        return 'Kamis';
      case DayOfWeek.friday:
        return 'Jumat';
      case DayOfWeek.saturday:
        return 'Sabtu';
      case DayOfWeek.sunday:
        return 'Minggu';
    }
  }

  /// Sesuai DateTime.weekday Dart: Senin = 1 ... Minggu = 7.
  int get isoWeekday => DayOfWeek.values.indexOf(this) + 1;

  static DayOfWeek fromIsoWeekday(int weekday) => DayOfWeek.values[weekday - 1];

  static DayOfWeek fromString(String value) {
    return DayOfWeek.values.firstWhere((d) => d.name == value);
  }
}

class ClassSchedule {
  final String id;
  final String name;
  final String trainerName;
  final DayOfWeek dayOfWeek;
  final String startTime; // format "HH:mm"
  final String endTime; // format "HH:mm"
  final int capacity;
  final String? description;

  const ClassSchedule({
    required this.id,
    required this.name,
    required this.trainerName,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.capacity,
    this.description,
  });

  /// Tanggal kejadian kelas ini berikutnya dari sekarang (termasuk hari ini
  /// kalau jam kelas belum lewat). Dipakai sebagai default tanggal saat
  /// membuka halaman booking.
  DateTime get nextOccurrenceDate {
    final now = DateTime.now();
    var daysToAdd = (dayOfWeek.isoWeekday - now.weekday) % 7;
    var candidate = DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));

    if (daysToAdd == 0) {
      final endParts = endTime.split(':');
      final endDateTime = DateTime(now.year, now.month, now.day,
          int.parse(endParts[0]), int.parse(endParts[1]));
      if (now.isAfter(endDateTime)) {
        candidate = candidate.add(const Duration(days: 7));
      }
    }
    return candidate;
  }

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'] as String,
      name: map['name'] as String,
      trainerName: map['trainer_name'] as String,
      dayOfWeek: DayOfWeekX.fromString(map['day_of_week'] as String),
      startTime: (map['start_time'] as String).substring(0, 5),
      endTime: (map['end_time'] as String).substring(0, 5),
      capacity: map['capacity'] as int,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'trainer_name': trainerName,
      'day_of_week': dayOfWeek.name,
      'start_time': startTime,
      'end_time': endTime,
      'capacity': capacity,
      'description': description,
    };
  }
}
