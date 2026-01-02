import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../l10n/app_localizations.dart';
import '../../root_gate.dart';
import '../../data/user_profile_repository.dart';

class SettingsScreen extends StatefulWidget {
  final String email;
  final String role;

  const SettingsScreen({super.key, required this.email, required this.role});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _remindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkTheme = false;
  String _language = 'English';
  String _previousLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _language = 'English';
    _previousLanguage = _language;
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootGate()),
      (route) => false,
    );
  }

  /// Returns a tuple (years, months) between birth and now.
  (int, int) _ageYearsMonths(DateTime birth, DateTime now) {
    int years = now.year - birth.year;
    int months = now.month - birth.month;

    // Adjust years if birthday hasn't occurred yet this year
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      years -= 1;
    }

    // Compute months within the current year span
    months = now.month - birth.month;
    if (now.day < birth.day) {
      months -= 1;
    }
    if (months < 0) {
      months += 12;
    }
    // Guard rails
    if (years < 0) years = 0;
    if (months < 0) months = 0;
    return (years, months);
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          loc.t('settings'),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(loc.t('account')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: Text(loc.t('email')),
                  subtitle: Text(widget.email),
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: Text(loc.t('role')),
                  subtitle: Text(
                    widget.role == 'patient' ? loc.t('patient') : widget.role,
                  ),
                ),
                if (uid != null) const Divider(height: 0),
                if (uid != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: UserProfileRepository().watchProfile(uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ListTile(
                          leading: Icon(Icons.cake_outlined),
                          title: SizedBox(
                            height: 16,
                            child: LinearProgressIndicator(minHeight: 4),
                          ),
                        );
                      }

                      final data = snapshot.data?.data();
                      final ts = data?['birthDate'] as Timestamp?;
                      String subtitleText;
                      if (ts == null) {
                        subtitleText = loc.t('notAvailable');
                      } else {
                        final bd = ts.toDate();
                        final age = _ageYearsMonths(bd, DateTime.now());
                        subtitleText =
                            '${age.$1} ${loc.t('years')} · ${age.$2} ${loc.t('months')}';
                      }

                      return ListTile(
                        leading: const Icon(Icons.cake_outlined),
                        title: Text(loc.t('age')),
                        subtitle: Text(subtitleText),
                      );
                    },
                  ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(loc.t('logout')),
                  onTap: _logout,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(loc.t('notifications')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(loc.t('reminders')),
                  value: _remindersEnabled,
                  onChanged: (val) => setState(() => _remindersEnabled = val),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: Text(loc.t('sound')),
                  value: _soundEnabled,
                  onChanged: (val) => setState(() => _soundEnabled = val),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: Text(loc.t('vibration')),
                  value: _vibrationEnabled,
                  onChanged: (val) => setState(() => _vibrationEnabled = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(loc.t('preferences')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(loc.t('language')),
                  trailing: DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: 'English',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(value: 'Hebrew', child: Text('Hebrew')),
                    ],
                    onChanged: (val) async {
                      if (val == null || val == _language) return;
                      final confirmed = await _confirmLanguageChange(val);
                      if (confirmed) {
                        setState(() {
                          _language = val;
                          _previousLanguage = val;
                        });
                      } else {
                        setState(() {
                          _language = _previousLanguage;
                        });
                      }
                    },
                  ),
                ),
                const Divider(height: 0),
                SwitchListTile(
                  title: Text(loc.t('darkTheme')),
                  value: _darkTheme,
                  onChanged: (val) => setState(() => _darkTheme = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionHeader(loc.t('about')),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(loc.t('appName')),
              subtitle: Text(
                '${loc.t('appVersion')}\n${loc.t('appDescription')}',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2E2E2E),
        ),
      ),
    );
  }

  Future<bool> _confirmLanguageChange(String newLang) async {
    final targetIsHebrew = newLang == 'Hebrew';
    final targetLabel = targetIsHebrew ? 'עברית' : 'English';
    final title = targetIsHebrew
        ? 'להחליף שפה ל$targetLabel?'
        : 'Change language to $targetLabel?';
    final message = targetIsHebrew
        ? 'האם לשנות את השפה ל$targetLabel?'
        : 'Switch language to $targetLabel?';
    final yesText = targetIsHebrew ? 'כן' : 'Yes';
    final noText = targetIsHebrew ? 'לא' : 'No';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(noText),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(yesText),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
