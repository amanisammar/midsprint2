import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class ProfileAchievementsRow extends StatelessWidget {
  final List<String> badges;
  const ProfileAchievementsRow({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.emoji_events_outlined, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(child: Text(context.loc.t('keepStreakEarnBadges'))),
            TextButton(
              onPressed: () {},
              child: Text(context.loc.t('learnMore')),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.loc.t('badges'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 82,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: badges.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return Container(
                width: 76,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.amber),
                    const SizedBox(height: 6),
                    Text(badges[index], style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
