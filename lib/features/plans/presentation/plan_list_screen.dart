import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/app_search_field.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/membership_plan.dart';
import 'package:gym_management_system/providers/plans_provider.dart';

class PlanListScreen extends ConsumerStatefulWidget {
  const PlanListScreen({super.key});

  @override
  ConsumerState<PlanListScreen> createState() => _PlanListScreenState();
}

class _PlanListScreenState extends ConsumerState<PlanListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final plansResult = ref.watch(plansControllerProvider);

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
        Expanded(
          child: plansResult.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(plansControllerProvider),
            ),
            data: (plans) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = plans
                  .where((p) =>
                      query.isEmpty ||
                      p.name.toLowerCase().contains(query) ||
                      p.features.any(
                          (f) => f.toLowerCase().contains(query)))
                  .toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.card_membership,
                  title: query.isEmpty ? strings.emptyPlans : strings.emptyFiltered,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _PlanCard(plan: filtered[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({required this.plan});

  final MembershipPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    return Card(
      color: plan.isActive ? null : theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/plans/form', extra: plan),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(plan.isActive
                        ? strings.statusActive
                        : strings.statusCancelled),
                    backgroundColor: plan.isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.schedule,
                      label: strings.duration,
                      value: '${plan.durationDays} ${strings.days}',
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.payments_outlined,
                      label: strings.price,
                      value: Formatters.money(plan.price),
                    ),
                  ),
                  Expanded(
                    child: _MiniStat(
                      icon: Icons.fitness_center,
                      label: strings.sessions,
                      value: plan.isUnlimitedSessions
                          ? strings.sessionsUnlimited
                          : '${plan.sessions}',
                    ),
                  ),
                ],
              ),
              if (plan.features.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final feature in plan.features)
                      Chip(
                        label: Text(feature),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}