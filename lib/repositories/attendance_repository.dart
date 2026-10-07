import 'package:gym_management_system/models/attendance_record.dart';

abstract class AttendanceRepository {
  Future<List<AttendanceRecord>> fetchOnDate(DateTime date);
  Future<AttendanceRecord> checkIn(String memberId);
  Future<void> checkOut(String recordId);
  Future<List<AttendanceRecord>> fetchByMember(String memberId);
}