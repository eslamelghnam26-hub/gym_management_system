import 'dart:convert';

import 'package:gym_management_system/core/errors/app_exception.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/repositories/announcement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DemoAnnouncementRepository implements AnnouncementRepository {
  DemoAnnouncementRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'demo_announcements';

  List<Announcement> _load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      final seeded = _seed();
      _save(seeded);
      return seeded;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    return [
      for (final item in list)
        Announcement.fromJson(item as Map<String, dynamic>)
    ];
  }

  void _save(List<Announcement> list) {
    _prefs.setString(_key, jsonEncode([for (final a in list) a.toJson()]));
  }

  List<Announcement> _seed() => [
        Announcement(
          id: 'ann_1',
          title: 'عرض الاشتراك الشهري',
          body: 'اشترك الآن وفعل باقة الشهر بأول 900 ج.م + شهر مجاني للخطة الأولى.',
          audience: AnnouncementAudience.members,
        ),
        Announcement(
          id: 'ann_2',
          title: 'صيانة أجهزة الكارديو',
          body: 'سيتم إغلاق منطقة الكارديو يوم الجمعة من 12 ظهرًا حتى 4 عصراً للصيانة الدورية.',
          audience: AnnouncementAudience.all,
        ),
      ];

  @override
  Future<List<Announcement>> fetchAll() async {
    final list = _load();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<Announcement> create(Announcement announcement) async {
    final id = 'ann_${DateTime.now().microsecondsSinceEpoch}';
    final created = announcement.copyWith(id: id);
    final list = _load();
    list.add(created);
    _save(list);
    return created;
  }

  @override
  Future<void> update(Announcement announcement) async {
    final list = _load();
    final index = list.indexWhere((a) => a.id == announcement.id);
    if (index == -1) {
      throw const DataException(code: 'not_found');
    }
    list[index] = announcement;
    _save(list);
  }

  @override
  Future<void> delete(String id) async {
    _save(_load().where((a) => a.id != id).toList());
  }
}