import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/widgets/confirm_dialog.dart';
import 'package:gym_management_system/core/widgets/empty_state.dart';
import 'package:gym_management_system/core/widgets/error_view.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/providers/announcements_provider.dart';

class AnnouncementListScreen extends ConsumerWidget {
  const AnnouncementListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final result = ref.watch(announcementsControllerProvider);
    final announcements = result.value ?? const <Announcement>[];
    final sorted = [...announcements]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorView(
        message: error.toString(),
        retryLabel: strings.retry,
        onRetry: () => ref.invalidate(announcementsControllerProvider),
      ),
      data: (_) {
        if (sorted.isEmpty) {
          return EmptyState(
            icon: Icons.campaign_outlined,
            title: strings.noAnnouncements,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          itemCount: sorted.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final announcement = sorted[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.campaign_outlined,
                            size: 20, color: AppColors.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            announcement.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          tooltip: strings.delete,
                          visualDensity: VisualDensity.compact,
                          onPressed: () async {
                            final confirmed = await confirmAction(
                              context,
                              title: strings.deleteConfirmTitle,
                              message: strings.deleteConfirmBody,
                              confirmLabel: strings.delete,
                              cancelLabel: strings.cancel,
                            );
                            if (!confirmed) return;
                            await ref
                                .read(announcementsControllerProvider.notifier)
                                .delete(announcement.id);
                          },
                          icon: const Icon(Icons.delete_outline, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(announcement.body,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Chip(
                          label: Text(strings.audienceLabel(announcement.audience),
                              style: Theme.of(context).textTheme.labelSmall),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.dateTime(announcement.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}