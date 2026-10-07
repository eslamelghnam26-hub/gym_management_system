import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/app_user.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/users_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

/// Staff account manager: lists every account in the `users` collection and
/// lets an admin promote/demote roles or remove users.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _changeRole(AppUser user, UserRole role) async {
    final users = ref.read(usersControllerProvider).value ?? const <AppUser>[];
    final admins = users.where((u) => u.role == UserRole.admin).length;
    final currentUid = ref.read(authControllerProvider).value?.uid;

    if (user.role == UserRole.admin && role != UserRole.admin && admins <= 1) {
      _toast('لا يمكن إزالة آخر مدير للنظام');
      return;
    }
    if (currentUid == user.uid && role != user.role) {
      _toast('لا يمكنك تغيير دورك بنفسك من هنا');
      return;
    }
    await ref.read(usersControllerProvider.notifier).save(user.copyWith(role: role));
    if (mounted) _toast('تم تحديث دور ${user.name}');
  }

  Future<void> _delete(AppUser user) async {
    final users = ref.read(usersControllerProvider).value ?? const <AppUser>[];
    final admins = users.where((u) => u.role == UserRole.admin).length;
    final currentUid = ref.read(authControllerProvider).value?.uid;

    if (currentUid == user.uid) {
      _toast('لا يمكنك حذف حسابك الحالي');
      return;
    }
    if (user.role == UserRole.admin && admins <= 1) {
      _toast('لا يمكن حذف آخر مدير للنظام');
      return;
    }
    final ok = await confirmAction(
      context,
      title: 'حذف مستخدم',
      message: 'حذف حساب «${user.name}»؟',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(usersControllerProvider.notifier).delete(user.uid);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersControllerProvider);
    final currentUid = ref.watch(authControllerProvider).value?.uid;

    return WebPage(
      title: 'المستخدمون والصلاحيات',
      subtitle: 'إدارة حسابات الكوادر داخل النظام',
      onRefresh: () => ref.invalidate(usersControllerProvider),
      child: usersAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل المستخدمين',
          onRetry: () => ref.invalidate(usersControllerProvider),
        ),
        data: (users) {
          final query = _search.text.trim().toLowerCase();
          final filtered = [
            for (final u in users)
              if (query.isEmpty ||
                  u.name.toLowerCase().contains(query) ||
                  u.email.toLowerCase().contains(query))
                u,
          ]..sort((a, b) => a.name.compareTo(b.name));

          return WebTableShell(
            title: 'الحسابات (${filtered.length})',
            searchController: _search,
            searchLabel: 'بحث بالاسم أو البريد...',
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('لا توجد نتائج')),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('الاسم')),
                        DataColumn(label: Text('البريد')),
                        DataColumn(label: Text('الدور')),
                        DataColumn(label: Text('تاريخ الإنشاء')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final user in filtered)
                          DataRow(cells: [
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primaryContainer,
                                  child: Text(
                                    user.initials,
                                    style: const TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${user.name}${user.uid == currentUid ? ' (أنت)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            )),
                            DataCell(Text(user.email)),
                            DataCell(
                              DropdownButton<UserRole>(
                                value: user.role,
                                isDense: true,
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final r in UserRole.values)
                                    DropdownMenuItem(
                                      value: r,
                                      child: Text(
                                        r.labelAr,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                ],
                                onChanged: (role) {
                                  if (role != null && role != user.role) {
                                    _changeRole(user, role);
                                  }
                                },
                              ),
                            ),
                            DataCell(Text(Formatters.date(user.createdAt))),
                            DataCell(IconButton(
                              tooltip: 'حذف',
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _delete(user),
                            )),
                          ]),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}