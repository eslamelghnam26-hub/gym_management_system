import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/repositories/member_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Offline implementation persisted to SharedPreferences, seeded with
/// realistic records referencing the seeded demo trainers (t_1..t_3) and
/// plans (plan_1..plan_3).
class DemoMemberRepository implements MemberRepository {
  DemoMemberRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_members';

  List<Member> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [for (final item in list) Member.fromJson(item as Map<String, dynamic>)];
  }

  void _save(List<Member> members) {
    _prefs.setString(_key, jsonEncode([for (final m in members) m.toJson()]));
  }

  List<Member> _seed() {
    final now = DateTime.now();
    Member member(
      String id,
      String name,
      String phone,
      String trainerId,
      String planId,
      DateTime start,
      DateTime end,
      MemberStatus status,
    ) =>
        Member(
          id: id,
          fullName: name,
          phone: phone,
          email: id == 'm_1' ? 'member@gym.com' : '$id@gym.com',
          gender: 'male',
          address: 'القاهرة',
          emergencyContact: '02-12345678',
          trainerId: trainerId,
          planId: planId,
          startDate: start,
          endDate: end,
          status: status,
        );

    return [
      member('m_1', 'أحمد محمود', '01001112223', 't_1', 'plan_1',
          now.subtract(const Duration(days: 20)), now.add(const Duration(days: 10)),
          MemberStatus.active),
      member('m_2', 'سارة عادل', '01002223334', 't_2', 'plan_2',
          now.subtract(const Duration(days: 30)), now.add(const Duration(days: 60)),
          MemberStatus.active),
      member('m_3', 'محمد كمال', '01003334445', 't_3', 'plan_3',
          now.subtract(const Duration(days: 100)), now.subtract(const Duration(days: 5)),
          MemberStatus.expired),
      member('m_4', 'نور هشام', '01004445556', 't_1', 'plan_1',
          now.add(const Duration(days: 3)), now.add(const Duration(days: 33)),
          MemberStatus.pending),
      member('m_5', 'عمر السيد', '01005556667', 't_2', 'plan_2',
          now.subtract(const Duration(days: 90)), now.subtract(const Duration(days: 60)),
          MemberStatus.cancelled),
      member('m_6', 'مريم خالد', '01006667778', 't_3', 'plan_1',
          now.subtract(const Duration(days: 10)), now.subtract(const Duration(days: 1)),
          MemberStatus.expired),
    ];
  }

  @override
  Future<List<Member>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Member> create(Member member) async {
    final id = 'm_${DateTime.now().microsecondsSinceEpoch}';
    final created = member.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Member member) async {
    final list = _load();
    final found = list.indexWhere((m) => m.id == member.id);
    if (found == -1) {
      throw const DataException(code: 'not_found');
    }
    list[found] = member;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((m) => m.id != id).toList());
  }
}