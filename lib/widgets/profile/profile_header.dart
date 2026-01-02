import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../l10n/app_localizations.dart';

class ProfileHeader extends StatelessWidget {
  final AppUser user;
  final VoidCallback onEdit;
  final VoidCallback onAvatarTap;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 36,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? const Icon(Icons.person, size: 32)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName.isNotEmpty
                          ? user.displayName
                          : 'PillCare Member',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.loc.t('level')} ${user.level}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
                label: Text(context.loc.t('edit')),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _LevelProgress(
            level: user.level,
            progress: user.levelProgress,
            nextPoints: user.nextLevelPoints,
          ),
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  final int level;
  final double progress;
  final int nextPoints;

  const _LevelProgress({
    required this.level,
    required this.progress,
    required this.nextPoints,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${context.loc.t('level')} $level',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text('$pct%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            minHeight: 10,
            backgroundColor: Colors.grey[200],
            color: const Color(0xFF2EC4B6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          context.loc.t(
            'nextLevelPoints',
            params: {'points': nextPoints.toString()},
          ),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
