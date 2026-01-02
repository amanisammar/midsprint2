import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class ProfileCareCircleSection extends StatelessWidget {
  const ProfileCareCircleSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups_2_outlined, color: Colors.teal),
              const SizedBox(width: 8),
              Text(
                context.loc.t('careCircle'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(context.loc.t('inviteFamilySupport')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              foregroundColor: Colors.black87,
            ),
            child: Text(context.loc.t('inviteComingSoon')),
          ),
        ],
      ),
    );
  }
}
