import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _shareAnalytics = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shareAnalytics = prefs.getBool('privacy_analytics') ?? false;
      _loading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  void _showPrivacyPolicy(BuildContext context) {
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('privacyPolicyTitle')),
        content: SingleChildScrollView(
          child: Text(loc.t('privacyPolicyContent')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('close')),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    final loc = context.loc;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.t('termsTitle')),
        content: SingleChildScrollView(child: Text(loc.t('termsContent'))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.t('close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: Text(loc.t('privacySecurity')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _shareAnalytics,
                        onChanged: (val) {
                          setState(() => _shareAnalytics = val);
                          _savePreference('privacy_analytics', val);
                        },
                        activeThumbColor: Colors.teal,
                        title: Text(loc.t('shareAnalytics')),
                        subtitle: Text(loc.t('shareAnalyticsDesc')),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.policy_outlined,
                          color: Colors.teal,
                        ),
                        title: Text(loc.t('privacyPolicy')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showPrivacyPolicy(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.description_outlined,
                          color: Colors.teal,
                        ),
                        title: Text(loc.t('termsOfService')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showTermsOfService(context),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.security_outlined,
                          color: Colors.teal,
                        ),
                        title: Text(loc.t('dataSecurity')),
                        subtitle: Text(loc.t('dataSecurityDesc')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          final loc = context.loc;
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(loc.t('dataSecurityTitle')),
                              content: Text(loc.t('dataSecurityMessage')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(loc.t('close')),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
