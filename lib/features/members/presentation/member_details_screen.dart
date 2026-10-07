import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/status_chip.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class MemberDetailsScreen extends ConsumerWidget {
  const MemberDetailsScreen({super.key, required this.member});

  final Member member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    Member current = member;
    for (final m in ref.watch(membersControllerProvider).value ??
        const <Member>[]) {
      if (m.id == member.id) {
        current = m;
        break;
      }
    }

    final trainer = current.trainerId == null
        ? null
        : ref.read(trainersControllerProvider.notifier).byId(current.trainerId!);
    final plan = current.planId == null
        ? null
        : ref.read(plansControllerProvider.notifier).byId(current.planId!);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.info),
        actions: [
          IconButton(
            tooltip: strings.edit,
            onPressed: () async {
              await context.push('/members/form', extra: current);
              if (context.mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              }
            },
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: strings.delete,
            onPressed: () => _delete(context, ref, strings),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                _HeaderCard(
                  member: current,
                  trainerName: trainer?.name,
                  planName: plan?.name,
                ),
                const SizedBox(height: 16),
                _InfoGrid(
                  member: current,
                  trainer: trainer,
                  plan: plan,
                ),
                if (current.notes != null && current.notes!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(strings.notes,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(current.notes!),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    AppStrings strings,
  ) async {
    final confirmed = await confirmAction(
      context,
      title: strings.deleteConfirmTitle,
      message: strings.deleteConfirmBody,
      confirmLabel: strings.delete,
      cancelLabel: strings.cancel,
    );
    if (!confirmed) return;
    await ref.read(membersControllerProvider.notifier).delete(member.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.savedSuccess),
            backgroundColor: AppColors.success),
      );
      context.pop();
    }
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.member,
    this.trainerName,
    this.planName,
  });

  final Member member;
  final String? trainerName;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                member.fullName.isNotEmpty ? member.fullName[0] : '?',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              member.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            StatusChip(status: member.status),
            const SizedBox(height: 8),
            Text(
              member.phone,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (planName != null) ...[
              const SizedBox(height: 12),
              Chip(
                avatar: const Icon(Icons.card_membership, size: 18),
                label: Text(planName!),
              ),
            ],
            if (trainerName != null) ...[
              const SizedBox(height: 8),
              Chip(
                avatar: const Icon(Icons.fitness_center, size: 18),
                label: Text(trainerName!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoGrid extends ConsumerWidget {
  const _InfoGrid({
    required this.member,
    this.trainer,
    this.plan,
  });

  final Member member;
  final Trainer? trainer;
  final MembershipPlan? plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);

    final rows = <_InfoRow>[
      _InfoRow(strings.email, member.email ?? '—'),
      _InfoRow(strings.gender, _genderLabel(strings, member.gender)),
      if (member.dateOfBirth != null)
        _InfoRow(strings.dateOfBirth, Formatters.date(member.dateOfBirth!)),
      _InfoRow(strings.address, member.address ?? '—'),
      _InfoRow(strings.emergencyContact, member.emergencyContact ?? '—'),
      _InfoRow(strings.startDate, Formatters.date(member.startDate)),
      _InfoRow(strings.endDate, Formatters.date(member.endDate)),
      _InfoRow(strings.remainingDays, '${member.remainingDays} ${strings.days}'),
      _InfoRow(strings.plan, plan?.name ?? '—'),
      _InfoRow(strings.assignedTrainer, trainer?.name ?? '—'),
      _InfoRow(strings.salary,
          trainer == null ? '—' : Formatters.money(trainer!.salary)),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.info,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        row.value,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _genderLabel(AppStrings strings, String? gender) {
    if (gender == null) return '—';
    return gender == 'female' ? strings.female : strings.male;
  }
}

class _InfoRow {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;
}