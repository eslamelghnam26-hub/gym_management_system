import 'package:gym_management_system/models/member.dart';

abstract class MemberRepository {
  Future<List<Member>> fetchAll();
  Future<Member> create(Member member);
  Future<void> update(Member member);
  Future<void> delete(String id);
}