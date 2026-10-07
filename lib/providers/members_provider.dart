import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_member_repository.dart';
import 'package:gym_management_system/repositories/firebase_member_repository.dart';
import 'package:gym_management_system/repositories/member_repository.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseMemberRepository();
  return DemoMemberRepository(ref.read(sharedPreferencesProvider));
});

class MembersController extends AsyncNotifier<List<Member>> {
  MemberRepository get _repo => ref.read(memberRepositoryProvider);

  @override
  Future<List<Member>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(Member member) async {
    await _repo.create(member);
    await _reload();
  }

  Future<void> save(Member member) async {
    await _repo.update(member);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  Member? byId(String id) {
    final list = state.value;
    if (list == null) return null;
    for (final member in list) {
      if (member.id == id) return member;
    }
    return null;
  }
}

final membersControllerProvider =
    AsyncNotifierProvider<MembersController, List<Member>>(MembersController.new);