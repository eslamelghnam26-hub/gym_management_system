import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';

/// Resolves the signed-in user to a gym member record by email. Demo seeding
/// maps the `member@gym.com` account to member `m_1`.
final currentMemberProvider = Provider<Member?>((ref) {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return null;
  final members = ref.watch(membersControllerProvider).value ?? const <Member>[];
  final email = user.email.trim().toLowerCase();
  for (final m in members) {
    if ((m.email ?? '').trim().toLowerCase() == email) return m;
  }
  return null;
});