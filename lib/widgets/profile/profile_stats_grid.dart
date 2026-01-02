import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class ProfileStatsGrid extends StatelessWidget {
  final int points;
  final int streakDays;
  final int badgesCount;
  final int level;
  final double progress;
  final int nextLevelPoints;

  const ProfileStatsGrid({
    super.key,
    required this.points,
    required this.streakDays,
    required this.badgesCount,
    required this.level,
    required this.progress,
    required this.nextLevelPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          title: context.loc.t('points'),
          value: points.toString(),
          icon: Icons.star_rounded,
          color: Colors.orange,
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: context.loc.t('streak'),
          value: '$streakDays ${context.loc.t('streakDaysSuffix')}',
          icon: Icons.local_fire_department,
          color: Colors.redAccent,
        ),
        const SizedBox(width: 12),
        _StatCard(
          title: context.loc.t('badges'),
          value: badgesCount.toString(),
          icon: Icons.emoji_events_outlined,
          color: Colors.indigo,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const Spacer(),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
