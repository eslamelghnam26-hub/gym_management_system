import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/app_search_field.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/attendance_record.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final attendanceResult = ref.watch(attendanceControllerProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final records = attendanceResult.value ?? const [];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppSearchField(
            controller: _searchController,
            hint: strings.searchHint,
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.how_to_reg_outlined,
                  value: '${records.where((r) => r.isCheckedIn).length}',
                  label: strings.present,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.event_busy_outlined,
                  value:
                      '${(membersResult.value ?? const []).where((m) => m.status == MemberStatus.active).length - records.length}',
                  label: strings.absent,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: attendanceResult.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(attendanceControllerProvider),
            ),
            data: (_) {
              final query = _searchController.text.trim().toLowerCase();
              final members = membersResult.value ?? const <Member>[];
              final filtered = members
                  .where((m) =>
                      query.isEmpty ||
                      m.fullName.toLowerCase().contains(query) ||
                      m.phone.contains(query))
                  .toList();
              if (filtered.isEmpty) {
                return const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'لا يوجد أعضاء',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final member = filtered[index];
                  final record = records
                      .where((r) => r.memberId == member.id)
                      .isEmpty
                      ? null
                      : records.firstWhere((r) => r.memberId == member.id);
                  return _AttendanceRow(
                    member: member,
                    record: record,
                    strings: strings,
                    onCheckIn: () => ref
                        .read(attendanceControllerProvider.notifier)
                        .checkIn(member.id),
                    onCheckOut: record == null
                        ? null
                        : () => ref
                            .read(attendanceControllerProvider.notifier)
                            .checkOut(record.id),
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

class _AttendanceRow extends StatelessWidget {
  const _AttendanceRow({
    required this.member,
    required this.record,
    required this.strings,
    required this.onCheckIn,
    this.onCheckOut,
  });

  final Member member;
  final AttendanceRecord? record;
  final AppStrings strings;
  final VoidCallback onCheckIn;
  final VoidCallback? onCheckOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedIn = record?.isCheckedIn ?? false;
    final checkedOut = record?.isCheckedOut ?? false;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0] : '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.fullName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.phone,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (checkedIn) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${strings.arrivedAt} ${record?.checkIn == null ? '' : Formatters.dateTime(record!.checkIn!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!checkedIn)
              FilledButton.tonal(
                onPressed: onCheckIn,
                child: Text(strings.checkIn),
              )
            else if (!checkedOut)
              OutlinedButton(
                onPressed: onCheckOut,
                child: Text(strings.checkOut),
              )
            else
              Chip(
                avatar: const Icon(Icons.done, size: 16),
                label: Text(strings.attendanceSummary),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ),
    );
  }
}