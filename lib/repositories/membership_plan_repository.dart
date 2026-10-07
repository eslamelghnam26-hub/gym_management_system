import 'package:gym_management_system/models/membership_plan.dart';

abstract class MembershipPlanRepository {
  Future<List<MembershipPlan>> fetchAll();
  Future<MembershipPlan> create(MembershipPlan plan);
  Future<void> update(MembershipPlan plan);
  Future<void> delete(String id);
}