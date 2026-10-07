import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/web_admin/widgets/web_dialogs.dart';
import 'package:gym_management_system/web_admin/widgets/web_page.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  DateTime _date = DateTime.now();
  int _revision = 0;
  String? _checkInMemberId;

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _checkIn() async {
    if (_checkInMemberId == null) return;
    await ref
        .read(attendanceControllerProvider.notifier)
        .checkIn(_checkInMemberId!);
    setState(() {
      _revision++;
      _checkInMemberId = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تسجيل الحضور')),
    );
  }

  Future<void> _checkOut(AttendanceRecord record) async {
    await ref
        .read(attendanceControllerProvider.notifier)
        .checkOut(record.id);
    setState(() => _revision++);
  }

  Future<void> _showHistory(Member member) async {
    final records = await ref
        .read(attendanceControllerProvider.notifier)
        .historyOf(member.id);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'سجل حضور ${member.fullName}',
                      style: Theme.of(dialogContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: records.isEmpty
                    ? const EmptyState(title: 'لا يوجد سجل حضور')
                    : SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('اليوم')),
                            DataColumn(label: Text('دخول')),
                            DataColumn(label: Text('خروج')),
                            DataColumn(label: Text('المدة')),
                          ],
                          rows: [
                            for (final r in records)
                              DataRow(cells: [
                                DataCell(Text(Formatters.date(r.date))),
                                DataCell(Text(
                                    r.checkIn == null ? '—' : _time(r.checkIn!))),
                                DataCell(Text(
                                    r.checkOut == null ? '—' : _time(r.checkOut!))),
                                DataCell(Text(_duration(r))),
                              ]),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _duration(AttendanceRecord r) {
    if (r.checkIn == null || r.checkOut == null) return '—';
    final diff = r.checkOut!.difference(r.checkIn!);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return '$h س ${m.toString().padLeft(2, '0')} د';
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersControllerProvider).value ?? const [];
    final memberName = {for (final m in members) m.id: m.fullName};

    return WebPage(
      title: 'الحضور',
      subtitle: 'تسجيل الدخول/الخروج اليومي',
      onRefresh: () {
        ref.invalidate(attendanceControllerProvider);
        ref.invalidate(membersControllerProvider);
        setState(() => _revision++);
      },
      child: FutureBuilder<List<AttendanceRecord>>(
        key: ValueKey('${_dayKey(_date)}-$_revision'),
        future: ref.read(attendanceRepositoryProvider).fetchOnDate(_date),
        builder: (context, snapshot) {
          final records = snapshot.data ?? const <AttendanceRecord>[];

          final presentIds = {for (final r in records) r.memberId};
          final absent = members.where((m) => !presentIds.contains(m.id)).toList();

          final infoCards = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _infoCard(context, 'الحاضرون', '${records.length}',
                  const Color(0xFF2E7D32), Icons.how_to_reg_outlined),
              _infoCard(context, 'الغائبون', '${absent.length}',
                  const Color(0xFFC62828), Icons.person_off_outlined),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_dayKey(_date)),
                      ),
                      const SizedBox(
                        width: 1,
                        height: 28,
                        child: VerticalDivider(),
                      ),
                      SizedBox(
                        width: 280,
                        child: FormDropdown<String>(
                          label: 'تسجيل دخول عضو',
                          value: _checkInMemberId,
                          items: [
                            for (final m in absent)
                              DropdownMenuItem(value: m.id, child: Text(m.fullName)),
                          ],
                          onChanged: (v) => setState(() => _checkInMemberId = v),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: absent.isEmpty || _checkInMemberId == null
                            ? null
                            : _checkIn,
                        icon: const Icon(Icons.login),
                        label: const Text('تسجيل دخول'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              infoCards,
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: AppLoadingView(label: 'جارٍ التحميل...'),
                        )
                      : snapshot.hasError
                          ? ErrorView(
                              message: 'تعذر تحميل الحضور',
                              onRetry: () => setState(() => _revision++),
                            )
                          : records.isEmpty
                              ? const EmptyState(title: 'لا يوجد حضور في هذا اليوم')
                              : SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columns: const [
                                      DataColumn(label: Text('العضو')),
                                      DataColumn(label: Text('دخول')),
                                      DataColumn(label: Text('خروج')),
                                      DataColumn(label: Text('المدة')),
                                      DataColumn(label: Text('')),
                                    ],
                                    rows: [
                                      for (final r in records)
                                        DataRow(cells: [
                                          DataCell(Text(
                                              memberName[r.memberId] ?? '—',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600))),
                                          DataCell(Text(
                                              r.checkIn == null ? '—' : _time(r.checkIn!))),
                                          DataCell(Text(
                                              r.checkOut == null ? '—' : _time(r.checkOut!))),
                                          DataCell(Text(_duration(r))),
                                          DataCell(Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (!r.isCheckedOut)
                                                OutlinedButton.icon(
                                                  onPressed: () => _checkOut(r),
                                                  icon: const Icon(
                                                      Icons.logout, size: 16),
                                                  label: const Text('خروج'),
                                                ),
                                              IconButton(
                                                tooltip: 'السجل',
                                                icon: const Icon(
                                                    Icons.history, size: 20),
                                                onPressed: () {
                                                  final member = members
                                                      .where((m) => m.id == r.memberId)
                                                      .firstOrNull;
                                                  if (member != null) {
                                                    _showHistory(member);
                                                  }
                                                },
                                              ),
                                            ],
                                          )),
                                        ]),
                                    ],
                                  ),
                                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoCard(BuildContext context, String label, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 10),
            Text(
              '$value $label',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}