import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/status_chip.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends ConsumerState<MembersPage> {
  final _search = TextEditingController();
  MemberStatus? _status;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openForm(Member? member) async {
    await showDialog(
      context: context,
      builder: (_) => _MemberFormDialog(initial: member),
    );
  }

  Future<void> _delete(Member member) async {
    final ok = await confirmAction(
      context,
      title: 'حذف عضو',
      message: 'هل أنت متأكد من حذف «${member.fullName}»؟ لا يمكن التراجع.',
      confirmLabel: 'حذف',
      cancelLabel: 'إلغاء',
    );
    if (!ok || !mounted) return;
    await ref.read(membersControllerProvider.notifier).delete(member.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حذف العضو')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(membersControllerProvider);
    final plansAsync = ref.watch(plansControllerProvider);
    final trainersAsync = ref.watch(trainersControllerProvider);

    final plans = plansAsync.value ?? const [];
    final trainers = trainersAsync.value ?? const [];
    final planName = {for (final p in plans) p.id: p.name};
    final trainerName = {for (final t in trainers) t.id: t.name};

    return WebPage(
      title: 'الأعضاء',
      subtitle: 'إدارة ملفات الأعضاء والاشتراكات',
      onRefresh: () {
        ref.invalidate(membersControllerProvider);
        ref.invalidate(plansControllerProvider);
        ref.invalidate(trainersControllerProvider);
      },
      actions: [
        FilledButton.icon(
          onPressed: () => _openForm(null),
          icon: const Icon(Icons.add),
          label: const Text('إضافة عضو'),
        ),
      ],
      child: membersAsync.when(
        loading: () => const AppLoadingView(label: 'جارٍ التحميل...'),
        error: (e, _) => ErrorView(
          message: 'تعذر تحميل الأعضاء',
          onRetry: () => ref.invalidate(membersControllerProvider),
        ),
        data: (members) {
          final query = _search.text.trim().toLowerCase();
          final filtered = members.where((m) {
            final matchesSearch = query.isEmpty ||
                m.fullName.toLowerCase().contains(query) ||
                m.phone.contains(query) ||
                (m.email?.toLowerCase().contains(query) ?? false);
            final matchesStatus = _status == null || m.status == _status;
            return matchesSearch && matchesStatus;
          }).toList()..sort((a, b) => a.fullName.compareTo(b.fullName));

          return WebTableShell(
            title: 'قائمة الأعضاء (${filtered.length})',
            subtitle: '${members.length} إجمالاً',
            searchController: _search,
            searchLabel: 'بحث بالاسم أو الهاتف أو البريد...',
            filters: _filters(context),
            child: filtered.isEmpty
                ? const EmptyState(
                    title: 'لا يوجد أعضاء مطابقون',
                    subtitle: 'غيّر البحث أو الفلاتر',
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('العضو')),
                        DataColumn(label: Text('الهاتف')),
                        DataColumn(label: Text('الباقة')),
                        DataColumn(label: Text('المدرب')),
                        DataColumn(label: Text('البداية')),
                        DataColumn(label: Text('النهاية')),
                        DataColumn(label: Text('متبقي')),
                        DataColumn(label: Text('الحالة')),
                        DataColumn(label: Text('')),
                      ],
                      rows: [
                        for (final m in filtered)
                          DataRow(cells: [
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(m.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                if (m.email != null)
                                  Text(m.email!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                              ],
                            )),
                            DataCell(Text(m.phone)),
                            DataCell(Text(planName[m.planId] ?? '—')),
                            DataCell(Text(trainerName[m.trainerId] ?? '—')),
                            DataCell(Text(Formatters.date(m.startDate))),
                            DataCell(Text(Formatters.date(m.endDate))),
                            DataCell(Text(
                              m.remainingDays < 0 ? 'منتهي' : '${m.remainingDays} يوم',
                              style: TextStyle(
                                color: m.remainingDays <= 14
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                            DataCell(StatusChip(status: m.status)),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'تعديل',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _openForm(m),
                                ),
                                IconButton(
                                  tooltip: 'حذف',
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () => _delete(m),
                                ),
                              ],
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

  Widget _filters(BuildContext context) {
    final chips = <MemberStatus?>[null, ...MemberStatus.values];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final status in chips)
          ChoiceChip(
            label: Text(status == null
                ? 'الكل'
                : status.labelAr),
            selected: _status == status,
            onSelected: (_) => setState(() => _status = status),
          ),
      ],
    );
  }
}

class _MemberFormDialog extends ConsumerStatefulWidget {
  const _MemberFormDialog({this.initial});

  final Member? initial;

  @override
  ConsumerState<_MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends ConsumerState<_MemberFormDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.fullName ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _email = TextEditingController(text: widget.initial?.email ?? '');
  late final _address = TextEditingController(text: widget.initial?.address ?? '');
  late final _emergency = TextEditingController(
      text: widget.initial?.emergencyContact ?? '');
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late DateTime _start;
  late DateTime _end;
  late MemberStatus _status;
  String? _planId;
  String? _trainerId;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start = widget.initial?.startDate ?? DateTime.now();
    _end = widget.initial?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _status = widget.initial?.status ?? MemberStatus.pending;
    _planId = widget.initial?.planId;
    _trainerId = widget.initial?.trainerId;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _emergency.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final member = Member(
        id: widget.initial?.id ?? '',
        fullName: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        address: _address.text.trim().isEmpty ? null : _address.text.trim(),
        emergencyContact:
            _emergency.text.trim().isEmpty ? null : _emergency.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        trainerId: _trainerId,
        planId: _planId,
        startDate: _start,
        endDate: _end,
        status: _status,
      );
      final notifier = ref.read(membersControllerProvider.notifier);
      if (widget.initial == null) {
        await notifier.add(member);
      } else {
        await notifier.save(member);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر الحفظ — حاول مرة أخرى')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = ref.watch(plansControllerProvider).value ?? const [];
    final trainers = ref.watch(trainersControllerProvider).value ?? const [];

    return WebFormDialog(
      title: widget.initial == null ? 'إضافة عضو جديد' : 'تعديل العضو',
      saving: _saving,
      onSave: _submit,
      width: 680,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FormRow(children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'الاسم الكامل *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'مطلوب'
                    : null,
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'الهاتف *'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'مطلوب'
                    : null,
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
              FormDropdown<String>(
                label: 'الدرجة / القطاع',
                value: _status.key,
                items: [
                  for (final s in MemberStatus.values)
                    DropdownMenuItem(value: s.key, child: Text(s.labelAr)),
                ],
                onChanged: (v) => setState(() {
                  _status = MemberStatus.fromKey(v);
                }),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              FormDropdown<String>(
                label: 'الباقة',
                value: _planId,
                items: [
                  DropdownMenuItem<String>(value: null, child: const Text('بدون')),
                  for (final p in plans)
                    DropdownMenuItem(value: p.id, child: Text(p.name)),
                ],
                onChanged: (v) => setState(() => _planId = v),
              ),
              FormDropdown<String>(
                label: 'المدرب',
                value: _trainerId,
                items: [
                  DropdownMenuItem<String>(value: null, child: const Text('بدون')),
                  for (final t in trainers)
                    DropdownMenuItem(value: t.id, child: Text(t.name)),
                ],
                onChanged: (v) => setState(() => _trainerId = v),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              FormDateField(
                label: 'تاريخ البداية',
                value: _start,
                onChanged: (v) => setState(() => _start = v ?? _start),
              ),
              FormDateField(
                label: 'تاريخ النهاية',
                value: _end,
                onChanged: (v) => setState(() => _end = v ?? _end),
              ),
            ]),
            const SizedBox(height: 14),
            FormRow(children: [
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              TextFormField(
                controller: _emergency,
                decoration: const InputDecoration(labelText: 'رقم الطوارئ'),
              ),
            ]),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظات'),
            ),
          ],
        ),
      ),
    );
  }
}