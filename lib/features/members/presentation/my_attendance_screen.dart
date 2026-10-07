import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/current_member_provider.dart';

class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final member = ref.watch(currentMemberProvider);
    final todayResult = ref.watch(attendanceControllerProvider);

    if (member == null) {
      return EmptyState(
        icon: Icons.person_off_outlined,
        title: strings.nothingHere,
      );
    }

    final todayRecord = todayResult.value
        ?.where((r) => r.memberId == member.id)
        .isEmpty ??
        true
        ? null
        : todayResult.value!.firstWhere((r) => r.memberId == member.id);
    final history = Future<List<AttendanceRecord>>(
        () => ref
            .read(attendanceControllerProvider.notifier)
            .historyOf(member.id));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: StatCard(
            icon: Icons.event_available_outlined,
            value: todayRecord == null
                ? strings.notCheckedInToday
                : todayRecord.isCheckedOut
                    ? strings.checkedOut
                    : strings.checkedIn,
            label: strings.todayStatus,
            color: todayRecord == null
                ? AppColors.danger
                : todayRecord.isCheckedOut
                    ? AppColors.success
                    : AppColors.accent,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AttendanceRecord>>(
            future: history,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final records = snapshot.data ?? const <AttendanceRecord>[];
              if (records.isEmpty) {
                return EmptyState(
                  icon: Icons.event_available_outlined,
                  title: strings.noAttendanceToday,
                );
              }
              records.sort((a, b) => b.date.compareTo(a.date));
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: records.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = records[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.event_available_outlined),
                      ),
                      title: Text(Formatters.date(r.date)),
                      subtitle: Text(
                        '${strings.arrivedAt} ${r.checkIn == null ? '—' : Formatters.dateTime(r.checkIn!)}'
                        '${r.checkOut == null ? '' : '        ${strings.leftAt} ${Formatters.dateTime(r.checkOut!)}'}',
                      ),
                      trailing: r.isCheckedOut
                          ? const Icon(Icons.check_circle,
                              color: AppColors.success)
                          : const Icon(Icons.check_circle_outline,
                              color: AppColors.accent),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}