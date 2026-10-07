import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/app_loading_view.dart';
import 'package:gym_management_system/core/widgets/app_search_field.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/models/trainer.dart';
import 'package:gym_management_system/providers/trainers_provider.dart';

class TrainerListScreen extends ConsumerStatefulWidget {
  const TrainerListScreen({super.key});

  @override
  ConsumerState<TrainerListScreen> createState() => _TrainerListScreenState();
}

class _TrainerListScreenState extends ConsumerState<TrainerListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final trainersResult = ref.watch(trainersControllerProvider);

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
          child: trainersResult.when(
            loading: () => const AppLoadingView(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              retryLabel: strings.retry,
              onRetry: () => ref.invalidate(trainersControllerProvider),
            ),
            data: (trainers) {
              final query = _searchController.text.trim().toLowerCase();
              final filtered = trainers.where((t) {
                final nameHit = query.isEmpty ||
                    t.name.toLowerCase().contains(query);
                final phoneHit = query.isEmpty ||
                    t.phone.toLowerCase().contains(query);
                final specHit = query.isEmpty ||
                    (t.specialization?.toLowerCase().contains(query) ?? false);
                return nameHit || phoneHit || specHit;
              }).toList();

              if (filtered.isEmpty) {
                return EmptyState(
                  icon: Icons.fitness_center,
                  title: query.isEmpty ? strings.emptyTrainers : strings.emptyFiltered,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trainer = filtered[index];
                  return _TrainerCard(
                    trainer: trainer,
                    onTap: () => context.push('/trainers/detail',
                        extra: trainer),
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

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({required this.trainer, required this.onTap});

  final Trainer trainer;
  final VoidCallback onTap;

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
                backgroundColor: theme.colorScheme.tertiaryContainer,
                child: Text(
                  trainer.name.isNotEmpty ? trainer.name[0] : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trainer.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trainer.specialization ?? '—',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trainer.phone,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Formatters.money(trainer.salary),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    trainer.schedule ?? '',
                    textAlign: TextAlign.end,
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