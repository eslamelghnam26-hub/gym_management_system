import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/stat_card.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/attendance_provider.dart';
import 'package:gym_management_system/providers/auth_provider.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class TrainerDashboardScreen extends ConsumerWidget {
  const TrainerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final user = ref.watch(authControllerProvider).value;
    final membersResult = ref.watch(membersControllerProvider);
    final attendanceResult = ref.watch(attendanceControllerProvider);
    final trainersResult = ref.watch(trainersControllerProvider);

    final trainers = trainersResult.value ?? const <Trainer>[];
    final email = user?.email.trim().toLowerCase() ?? '';
    final trainer = trainers
        .where((t) => (t.email ?? '').trim().toLowerCase() == email)
        .isEmpty
        ? null
        : trainers.firstWhere(
            (t) => (t.email ?? '').trim().toLowerCase() == email);
    final assigned = (membersResult.value ?? const <Member>[])
        .where((m) => trainer != null && m.trainerId == trainer.id)
        .toList();
    final presentIds = attendanceResult.value
            ?.where((r) => r.isCheckedIn)
            .map((r) => r.memberId)
            .toSet() ??
        const <String>{};
    final presentNow = assigned.where((m) => presentIds.contains(m.id)).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${strings.welcome} ${user?.name ?? ''} 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          strings.roleTrainer,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: StatCard(
                icon: Icons.group_outlined,
                value: '${assigned.length}',
                label: strings.assignedMembers,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatCard(
                icon: Icons.how_to_reg_outlined,
                value: '$presentNow',
                label: strings.present,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.assignedMembers,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/members'),
              child: Text(strings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (assigned.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: EmptyState(
                icon: Icons.group_outlined,
                title: strings.emptyMembers,
              ),
            ),
          )
        else
          for (final member in assigned)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName[0] : '?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  member.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(member.phone),
                trailing: presentIds.contains(member.id)
                    ? Chip(
                        avatar: const Icon(Icons.check_circle, size: 16),
                        label: Text(strings.checkedIn),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
                onTap: () => context.push('/members/detail', extra: member),
              ),
            ),
      ],
    );
  }
}