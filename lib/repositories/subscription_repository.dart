import 'package:gym_management_system/models/subscription.dart';

abstract class SubscriptionRepository {
  Future<List<Subscription>> fetchAll();
  Future<Subscription> create(Subscription subscription);
  Future<void> update(Subscription subscription);
  Future<void> delete(String id);
}