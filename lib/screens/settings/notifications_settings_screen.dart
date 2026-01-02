import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _remindersEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _dailySummary = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remindersEnabled = prefs.getBool('notifications_reminders') ?? true;
      _soundEnabled = prefs.getBool('notifications_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notifications_vibration') ?? true;
      _dailySummary = prefs.getBool('notifications_daily_summary') ?? false;
      _loading = false;
    });
  }

  Future<void> _savePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('Notifications & Reminders'),
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
                        value: _remindersEnabled,
                        onChanged: (val) {
                          setState(() => _remindersEnabled = val);
                          _savePreference('notifications_reminders', val);
                        },
                        activeThumbColor: Colors.teal,
                        title: const Text('Medicine reminders'),
                        subtitle: const Text(
                          'Get notified when it\'s time to take your medicine',
                        ),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _soundEnabled,
                        onChanged: (val) {
                          setState(() => _soundEnabled = val);
                          _savePreference('notifications_sound', val);
                        },
                        activeThumbColor: Colors.teal,
                        title: const Text('Sound'),
                        subtitle: const Text('Play sound with notifications'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _vibrationEnabled,
                        onChanged: (val) {
                          setState(() => _vibrationEnabled = val);
                          _savePreference('notifications_vibration', val);
                        },
                        activeThumbColor: Colors.teal,
                        title: const Text('Vibration'),
                        subtitle: const Text('Vibrate with notifications'),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        value: _dailySummary,
                        onChanged: (val) {
                          setState(() => _dailySummary = val);
                          _savePreference('notifications_daily_summary', val);
                        },
                        activeThumbColor: Colors.teal,
                        title: const Text('Daily summary'),
                        subtitle: const Text(
                          'Receive a daily summary of your adherence',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
