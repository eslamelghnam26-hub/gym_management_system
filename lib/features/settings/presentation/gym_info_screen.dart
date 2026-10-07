import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gym_management_system/core/localization/app_localization.dart';
import 'package:gym_management_system/core/utils/formatters.dart';
import 'package:gym_management_system/core/theme/app_colors.dart';
import 'package:gym_management_system/models/announcement.dart';
import 'package:gym_management_system/models/gym_settings.dart';
import 'package:gym_management_system/providers/announcements_provider.dart';
import 'package:gym_management_system/providers/gym_settings_provider.dart';

const _gymPhotos = [
  'assets/gym_images/gym_dumbbells.jpg',
  'assets/gym_images/gym_weight.jpg',
  'assets/gym_images/gym_dark.jpg',
  'assets/gym_images/gym_arena.jpg',
];

class GymInfoScreen extends ConsumerWidget {
  const GymInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(appStringsProvider);
    final theme = Theme.of(context);
    final settingsResult = ref.watch(gymSettingsProvider);
    final announcementsResult = ref.watch(announcementsControllerProvider);
    final settings = settingsResult.value ?? GymSettings.defaults;
    final announcements = (announcementsResult.value ?? const <Announcement>[])
        .where((a) => a.audience != AnnouncementAudience.trainers)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Stack(
                children: [
                  Image.asset(
                    'assets/gym_images/gym_arena.jpg',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 180,
                      color: AppColors.primary.withValues(alpha: 0.15),
                      child: const Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.35, 1.0],
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settings.gymName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          strings.gymInformation,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ContactRow(
                icon: Icons.place_outlined,
                value: settings.address.isEmpty
                    ? strings.notProvided
                    : settings.address,
              ),
              _ContactRow(
                icon: Icons.phone_outlined,
                value:
                    settings.phone.isEmpty ? strings.notProvided : settings.phone,
              ),
              _ContactRow(
                icon: Icons.email_outlined,
                value:
                    settings.email.isEmpty ? strings.notProvided : settings.email,
              ),
              _ContactRow(
                icon: Icons.schedule_outlined,
                value: settings.openingHours.isEmpty
                    ? strings.notProvided
                    : settings.openingHours,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          strings.gymGalleryTitle,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          strings.gymGallerySubtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 4),
            itemCount: _gymPhotos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final photo = _gymPhotos[index];
              return ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  photo,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 220,
                    color: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 40,
                      color: AppColors.primaryBright,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Text(
          strings.gymNews,
          style:
              theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (announcements.isEmpty)
          Text(
            strings.noAnnouncements,
            style: theme.textTheme.bodyMedium,
          )
        else
          for (final announcement in announcements)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(
                  Icons.campaign_outlined,
                  color: AppColors.accent,
                ),
                title: Text(
                  announcement.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(announcement.body),
                    Text(
                      Formatters.dateTime(announcement.createdAt),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}