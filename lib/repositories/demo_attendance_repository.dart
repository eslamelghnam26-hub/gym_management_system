import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/repositories/attendance_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoAttendanceRepository implements AttendanceRepository {
  DemoAttendanceRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_attendance';

  List<AttendanceRecord> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        AttendanceRecord.fromJson(item as Map<String, dynamic>)
    ];
  }

  void _save(List<AttendanceRecord> list) {
    _prefs.setString(_key, jsonEncode([for (final a in list) a.toJson()]));
  }

  List<AttendanceRecord> _seed() {
    final today = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(today.year, today.month, today.day, hour, minute);
    return [
      AttendanceRecord(
        id: 'a_1',
        memberId: 'm_1',
        date: today,
        checkIn: at(8, 15),
      ),
      AttendanceRecord(
        id: 'a_2',
        memberId: 'm_2',
        date: today,
        checkIn: at(10, 5),
      ),
      AttendanceRecord(
        id: 'a_3',
        memberId: 'm_6',
        date: today,
        checkIn: at(9, 30),
        checkOut: at(11, 45),
      ),
    ];
  }

  @override
  Future<List<AttendanceRecord>> fetchOnDate(DateTime date) async {
    final key = AttendanceRecord.dayKey(date);
    return _load().where((a) => AttendanceRecord.dayKey(a.date) == key).toList();
  }

  @override
  Future<AttendanceRecord> checkIn(String memberId) async {
    final today = DateTime.now();
    final list = _load();
    final existing = list.where((a) =>
        a.memberId == memberId &&
        AttendanceRecord.dayKey(a.date) == AttendanceRecord.dayKey(today));
    if (existing.isNotEmpty) return existing.first;
    final record = AttendanceRecord(
      id: 'a_${DateTime.now().microsecondsSinceEpoch}',
      memberId: memberId,
      date: today,
      checkIn: today,
    );
    list.add(record);
    _save(list);
    return record;
  }

  @override
  Future<void> checkOut(String recordId) async {
    final list = _load();
    final index = list.indexWhere((a) => a.id == recordId);
    if (index == -1) throw const DataException(code: 'not_found');
    final current = list[index];
    list[index] = AttendanceRecord(
      id: current.id,
      memberId: current.memberId,
      date: current.date,
      checkIn: current.checkIn,
      checkOut: DateTime.now(),
      createdAt: current.createdAt,
    );
    _save(list);
  }

  @override
  Future<List<AttendanceRecord>> fetchByMember(String memberId) async {
    final list = _load().where((a) => a.memberId == memberId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}