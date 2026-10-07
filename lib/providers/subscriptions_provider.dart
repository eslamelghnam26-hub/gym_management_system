import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/config/app_config.dart';
import 'package:gym_management_system/models/subscription.dart';
import 'package:gym_management_system/providers/shared_prefs_provider.dart';
import 'package:gym_management_system/repositories/demo_subscription_repository.dart';
import 'package:gym_management_system/repositories/firebase_subscription_repository.dart';
import 'package:gym_management_system/repositories/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  if (AppConfig.isFirebase) return FirebaseSubscriptionRepository();
  return DemoSubscriptionRepository(ref.read(sharedPreferencesProvider));
});

class SubscriptionsController extends AsyncNotifier<List<Subscription>> {
  SubscriptionRepository get _repo => ref.read(subscriptionRepositoryProvider);

  @override
  Future<List<Subscription>> build() => _repo.fetchAll();

  Future<void> _reload() async {
    try {
      state = AsyncData(await _repo.fetchAll());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String> add(Subscription subscription) async {
    final created = await _repo.create(subscription);
    await _reload();
    return created.id;
  }

  Future<void> save(Subscription subscription) async {
    await _repo.update(subscription);
    await _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await _reload();
  }

  Subscription? byId(String id) {
    final list = state.value;
    if (list == null) return null;
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<Subscription> forMember(String memberId) {
    final list = state.value ?? const <Subscription>[];
    return list.where((s) => s.memberId == memberId).toList();
  }
}

final subscriptionsControllerProvider =
    AsyncNotifierProvider<SubscriptionsController, List<Subscription>>(
        SubscriptionsController.new);