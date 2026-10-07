import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/app_search_field.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/widgets/status_chip.dart';
import 'package:gym_management_system/models/member.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/members_provider.dart';
import 'package:gym_management_system/providers/plans_provider.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class MemberListScreen extends ConsumerStatefulWidget {
  const MemberListScreen({super.key});

  @override
  ConsumerState<MemberListScreen> createState() => _MemberListScreenState();
}

class _MemberListScreenState extends ConsumerState<MemberListScreen> {
  final _searchController = TextEditingController();
  MemberStatus? _statusFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final membersResult = ref.watch(membersControllerProvider);
    final trainersResult = ref.watch(trainersControllerProvider);
    final plansResult = ref.watch(plansControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSearchField(
                controller: _searchController,
                hint: strings.searchHint,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              FilterChip(
                label: Text(strings.all),
                selected: _statusFilter == null,
                onSelected: (_) => setState(() => _statusFilter = null),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final status in MemberStatus.values) ...[
                      const SizedBox(width: 8),
                      FilterChip(
                        label: Text(_statusLabel(strings, status)),
                        selected: _statusFilter == status,
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: membersResult.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(membersControllerProvider),
            ),
            data: (members) {
              final trainerMap = <String, Trainer>{
                for (final t in trainersResult.value ?? const <Trainer>[]) t.id: t,
              };
              final planMap = <String, MembershipPlan>{
                for (final p in plansResult.value ?? const <MembershipPlan>[]) p.id: p,
              };
              final query = _searchController.text.trim().toLowerCase();
              final filtered = members.where((m) {
                final nameHit = query.isEmpty ||
                    m.fullName.toLowerCase().contains(query);
                final phoneHit =
                    query.isEmpty || m.phone.toLowerCase().contains(query);
                final statusHit =
                    _statusFilter == null || m.status == _statusFilter;
                return (nameHit || phoneHit) && statusHit;
              }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.people_outline,
                  title: query.isEmpty && _statusFilter == null
                      ? strings.emptyMembers
                      : strings.emptyFiltered,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final member = filtered[index];
                  return _MemberCard(
                    member: member,
                    trainerName: member.trainerId == null
                        ? null
                        : trainerMap[member.trainerId]?.name,
                    planName: member.planId == null
                        ? null
                        : planMap[member.planId]?.name,
                    onTap: () => context.push('/members/detail',
                        extra: member),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusLabel(AppStrings strings, MemberStatus status) {
    return switch (status) {
      MemberStatus.active => strings.statusActive,
      MemberStatus.expired => strings.statusExpired,
      MemberStatus.pending => strings.statusPending,
      MemberStatus.cancelled => strings.statusCancelled,
    };
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    this.trainerName,
    this.planName,
  });

  final Member member;
  final VoidCallback onTap;
  final String? trainerName;
  final String? planName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  member.fullName.isNotEmpty
                      ? member.fullName[0]
                      : '?',
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
                      style: theme.textTheme.titleMedium?.copyWith(
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
                    if (planName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        planName!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusChip(status: member.status),
                  const SizedBox(height: 8),
                  if (trainerName != null)
                    Text(
                      trainerName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}