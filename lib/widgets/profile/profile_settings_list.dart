import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({
    super.key,
    required this.shareWithFamily,
    required this.onToggleShare,
    required this.onOpenNotifications,
    required this.onOpenPrivacy,
    required this.onOpenHelp,
    required this.onOpenAbout,
    required this.onOpenDelete,
    required this.onSignOut,
  });

  final bool shareWithFamily;
  final ValueChanged<bool> onToggleShare;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenAbout;
  final VoidCallback onOpenDelete;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: shareWithFamily,
            onChanged: onToggleShare,
            activeThumbColor: Colors.teal,
            title: Text(loc.t('shareWithFamily')),
            subtitle: Text(loc.t('shareWithFamilyDesc')),
          ),
          const Divider(height: 1),
          _ProfileSettingItem(
            icon: Icons.notifications_none,
            title: loc.t('notifications'),
            subtitle: loc.t('notificationsSubtitle'),
            onTap: onOpenNotifications,
          ),
          _ProfileSettingItem(
            icon: Icons.lock_outline,
            title: loc.t('privacySecurity'),
            subtitle: loc.t('privacySecuritySubtitle'),
            onTap: onOpenPrivacy,
          ),
          _ProfileSettingItem(
            icon: Icons.help_outline,
            title: loc.t('helpSupport'),
            subtitle: loc.t('helpSupportSubtitle'),
            onTap: onOpenHelp,
          ),
          _ProfileSettingItem(
            icon: Icons.info_outline,
            title: loc.t('about'),
            subtitle: loc.t('aboutSubtitle'),
            onTap: onOpenAbout,
          ),
          _ProfileSettingItem(
            icon: Icons.delete_outline,
            title: loc.t('deleteAccount'),
            subtitle: '',
            onTap: onOpenDelete,
            iconColor: Colors.redAccent,
            textColor: Colors.redAccent,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: Text(
              loc.t('signOut'),
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _ProfileSettingItem extends StatelessWidget {
  const _ProfileSettingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final color = textColor ?? Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: iconColor ?? Colors.teal),
          title: Text(title, style: TextStyle(color: color)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
