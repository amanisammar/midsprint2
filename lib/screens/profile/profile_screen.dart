import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_status.dart';
import '../../models/app_user.dart';
import '../../root_gate.dart';
import '../../services/profile_service.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_stats_grid.dart';
import '../../widgets/profile/profile_achievements_row.dart';
import '../../widgets/profile/profile_care_circle_section.dart';
import '../../widgets/profile/profile_settings_list.dart';
import 'edit_profile_sheet.dart';
import '../auth/login_screen.dart';
import '../settings/notifications_settings_screen.dart';
import '../settings/privacy_settings_screen.dart';
import '../settings/help_support_screen.dart';
import '../settings/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();

  Future<({int taken, int missed, double adherence})> _loadWeeklyStats(
    String uid,
  ) async {
    final logs = await _service.getDoseLogsLast7Days(uid);
    return _service.computeAdherenceFromLogs(logs);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    if (auth.status == AuthStatus.unauthenticated) {
      return const LoginScreen();
    }
    final user = auth.user;
    if (user == null) {
      return const LoginScreen();
    }

    return StreamBuilder<AppUser?>(
      stream: _service.getUserStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.loc.t('couldNotLoadWeeklyStats')),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text(context.loc.t('retry')),
                  ),
                ],
              ),
            ),
          );
        }

        final appUser = snapshot.data;
        if (appUser == null) {
          return Scaffold(
            body: Center(
              child: Text(context.loc.t('notAvailable')),
            ), // Should not happen
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF7F4EF),
          appBar: AppBar(
            title: Text(context.loc.t('profile')),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async => setState(() {}),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ProfileHeader(
                      user: appUser,
                      onEdit: () =>
                          EditProfileSheet.show(context, appUser, _service),
                      onAvatarTap: () => EditProfileSheet.show(
                        context,
                        appUser,
                        _service,
                        focusAvatar: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ProfileStatsGrid(
                      points: appUser.points,
                      streakDays: appUser.streakDays,
                      badgesCount: 0,
                      level: appUser.level,
                      progress: appUser.levelProgress,
                      nextLevelPoints: appUser.nextLevelPoints,
                    ),
                    const SizedBox(height: 20),
                    FutureBuilder<({int taken, int missed, double adherence})>(
                      future: _loadWeeklyStats(appUser.uid),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const _CardShell(height: 160);
                        }
                        if (snap.hasError) {
                          return _ErrorCard(
                            message: context.loc.t('couldNotLoadWeeklyStats'),
                          );
                        }
                        final data =
                            snap.data ?? (taken: 0, missed: 0, adherence: 0.0);
                        final total = data.taken + data.missed;
                        if (total == 0) {
                          return _EmptyCard(
                            title: context.loc.t('trackingTitle'),
                            message: context.loc.t('trackingEmpty'),
                          );
                        }
                        final adherence = data.adherence
                            .clamp(0, 100)
                            .toDouble();
                        return _TrackingCard(
                          taken: data.taken,
                          missed: data.missed,
                          adherence: adherence,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const ProfileAchievementsRow(badges: []),
                    const SizedBox(height: 16),
                    const ProfileCareCircleSection(),
                    const SizedBox(height: 16),
                    ProfileSettingsList(
                      shareWithFamily: appUser.shareWithFamily,
                      onToggleShare: (val) =>
                          _service.updateShareWithFamily(appUser.uid, val),
                      onOpenNotifications: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsSettingsScreen(),
                        ),
                      ),
                      onOpenPrivacy: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      ),
                      onOpenHelp: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HelpSupportScreen(),
                        ),
                      ),
                      onOpenAbout: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                      onOpenDelete: () => _confirmDeleteAccount(context),
                      onSignOut: () async {
                        await context.read<AuthNotifier>().signOut();
                        if (!context.mounted) return;
                        // Navigate to RootGate which will redirect to LoginScreen
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const RootGate()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.loc.t('deleteAccount')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.t('deleteAccountConfirm'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(context.loc.t('deleteAccountWarning')),
            const SizedBox(height: 8),
            Text('• ${context.loc.t('allMedicines')}'),
            Text('• ${context.loc.t('doseLogs')}'),
            Text(
              '• ${context.loc.t('profile')} & ${context.loc.t('settings')}',
            ),
            Text('• ${context.loc.t('personalInformation')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.loc.t('deleteForever')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _deleteAccount(context);
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      final auth = context.read<AuthNotifier>();
      final user = auth.user;
      if (user == null) return;

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Deleting account...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Delete Firestore user data
      await _service.deleteUserData(user.uid);

      // Delete Firebase Auth account
      await user.delete();

      // Sign out
      await auth.signOut();

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        // Navigate to RootGate which will redirect to LoginScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RootGate()),
          (route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account deleted successfully')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${e.toString()}')),
        );
      }
    }
  }
}

class _CardShell extends StatelessWidget {
  final double height;
  const _CardShell({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: Text(context.loc.t('close')),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String title;
  final String message;
  const _EmptyCard({required this.title, required this.message});

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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: Colors.teal),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrackingCard extends StatelessWidget {
  final int taken;
  final int missed;
  final double adherence;
  const _TrackingCard({
    required this.taken,
    required this.missed,
    required this.adherence,
  });

  @override
  Widget build(BuildContext context) {
    final percent = adherence.clamp(0, 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.t('trackingTitle'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatChip(
                label: context.loc.t('taken7d'),
                value: taken.toString(),
                color: Colors.green,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: context.loc.t('missed7d'),
                value: missed.toString(),
                color: Colors.redAccent,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: context.loc.t('adherence'),
                value: '$percent%',
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
