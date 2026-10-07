import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/attendance_repository.dart';
import 'package:gym_management_system/repositories/demo_attendance_repository.dart';
import 'package:gym_management_system/repositories/firebase_attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseAttendanceRepository();
  return DemoAttendanceRepository(ref.read(sharedPreferencesProvider));
});

/// Holds *today's* attendance list; member history is fetched on demand.
class AttendanceController extends AsyncNotifier<List<AttendanceRecord>> {
  AttendanceRepository get _repo => ref.read(attendanceRepositoryProvider);

  @override
  Future<List<AttendanceRecord>> build() {
    final now = DateTime.now();
    return _repo.fetchOnDate(DateTime(now.year, now.month, now.day));
  }

  Future<void> _reload() async {
    try {
      final now = DateTime.now();
      state = AsyncData(
          await _repo.fetchOnDate(DateTime(now.year, now.month, now.day)));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> checkIn(String memberId) async {
    await _repo.checkIn(memberId);
    await _reload();
  }

  Future<void> checkOut(String recordId) async {
    await _repo.checkOut(recordId);
    await _reload();
  }

  AttendanceRecord? todayFor(String memberId) {
    final list = state.value;
    if (list == null) return null;
    for (final r in list) {
      if (r.memberId == memberId) return r;
    }
    return null;
  }

  Future<List<AttendanceRecord>> historyOf(String memberId) =>
      _repo.fetchByMember(memberId);
}

final attendanceControllerProvider =
    AsyncNotifierProvider<AttendanceController, List<AttendanceRecord>>(
        AttendanceController.new);