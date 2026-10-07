import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_membership_plan_repository.dart';
import 'package:gym_management_system/repositories/firebase_membership_plan_repository.dart';
import 'package:gym_management_system/repositories/membership_plan_repository.dart';

final planRepositoryProvider = Provider<MembershipPlanRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseMembershipPlanRepository();
  return DemoMembershipPlanRepository(ref.read(sharedPreferencesProvider));
});

class PlansController extends AsyncNotifier<List<MembershipPlan>> {
  MembershipPlanRepository get _repo => ref.read(planRepositoryProvider);

  @override
  Future<List<MembershipPlan>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> add(MembershipPlan plan) async {
    await _repo.create(plan);
    await _reload();
  }

  Future<void> save(MembershipPlan plan) async {
    await _repo.update(plan);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  MembershipPlan? byId(String id) {
    final list = state.value;
    if (list == null) return null;
    for (final plan in list) {
      if (plan.id == id) return plan;
    }
    return null;
  }
}

final plansControllerProvider =
    AsyncNotifierProvider<PlansController, List<MembershipPlan>>(PlansController.new);