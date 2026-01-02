import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/history_service.dart';
import '../../services/dose_log_service.dart';
import '../../l10n/app_localizations.dart';

/// Screen showing 7-day medicine adherence history
class History7DaysScreen extends StatefulWidget {
  const History7DaysScreen({super.key});

  @override
  State<History7DaysScreen> createState() => _History7DaysScreenState();
}

class _History7DaysScreenState extends State<History7DaysScreen> {
  final _historyService = HistoryService();
  final _doseLogService = DoseLogService();
  bool _isBackfilling = false;

  @override
  void initState() {
    super.initState();
    _checkAndBackfill();
  }

  Future<void> _checkAndBackfill() async {
    final prefs = await SharedPreferences.getInstance();
    final didBackfill = prefs.getBool('didBackfillDoseLogs') ?? false;

    if (!didBackfill) {
      setState(() => _isBackfilling = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await _doseLogService.backfillDoseLogsFromDailyTaken(user.uid);
          await prefs.setBool('didBackfillDoseLogs', true);
          setState(() {
            _isBackfilling = false;
          });
          // Show brief success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(context.loc.t('historyLoadedSuccess')),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          setState(() => _isBackfilling = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${context.loc.t('errorLoadingHistory')}: $e')),
            );
          }
        }
      } else {
        setState(() => _isBackfilling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(context.loc.t('history7Days')),
          backgroundColor: const Color(0xFF23C3AE),
          foregroundColor: Colors.white,
        ),
        body: Center(child: Text(context.loc.t('signInToView'))),
      );
    }

    if (_isBackfilling) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('7-Day History'),
          backgroundColor: const Color(0xFF23C3AE),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
            ] + [
              Text(context.loc.t('loadingHistory')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('7-Day History'),
        backgroundColor: const Color(0xFF23C3AE),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<DaySummary>>(
        future: _historyService.getLast7DaysSummary(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${context.loc.t('historyError')}: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: Text(context.loc.t('retry')),
                  ),
                ],
              ),
            );
          }

          final summaries = snapshot.data ?? [];

          if (summaries.isEmpty) {
            return Center(
              child: Text(context.loc.t('noHistoryData')),
            );
          }

          // Calculate overall stats
          final totalScheduled = summaries.fold<int>(
            0,
            (sum, s) => sum + s.scheduledCount,
          );
          final totalTaken = summaries.fold<int>(
            0,
            (sum, s) => sum + s.takenCount,
          );
          final totalMissed = summaries.fold<int>(
            0,
            (sum, s) => sum + s.missedCount,
          );
          final overallAdherence = totalScheduled > 0
              ? (totalTaken / totalScheduled) * 100
              : 0.0;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Overall summary card
                _OverallSummaryCard(
                  totalScheduled: totalScheduled,
                  totalTaken: totalTaken,
                  totalMissed: totalMissed,
                  adherencePercent: overallAdherence,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  context.loc.t('dailyBreakdown'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2B2D31),
                      ),
                ),
                const SizedBox(height: 12),

                // Daily cards
                ...summaries.map((summary) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayCard(summary: summary),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OverallSummaryCard extends StatelessWidget {
  final int totalScheduled;
  final int totalTaken;
  final int totalMissed;
  final double adherencePercent;

  const _OverallSummaryCard({
    required this.totalScheduled,
    required this.totalTaken,
    required this.totalMissed,
    required this.adherencePercent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF23C3AE), Color(0xFF1E9B8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc.t('summary7Days'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  label: context.loc.t('taken'),
                  value: totalTaken.toString(),
                  icon: Icons.check_circle,
                ),
                _StatColumn(
                  label: context.loc.t('missed'),
                  value: totalMissed.toString(),
                  icon: Icons.cancel,
                ),
                _StatColumn(
                  label: context.loc.t('total'),
                  value: totalScheduled.toString(),
                  icon: Icons.medication,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.loc.t('adherence'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${adherencePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  final DaySummary summary;

  const _DayCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(summary.date);
    final dayLabel = isToday
        ? context.loc.t('today')
        : DateFormat('EEEE, MMM d').format(summary.date);

    final adherenceColor = summary.adherencePercent >= 80
        ? Colors.green
        : summary.adherencePercent >= 50
            ? Colors.orange
            : Colors.red;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dayLabel,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isToday ? const Color(0xFF23C3AE) : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: adherenceColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: adherenceColor, width: 1.5),
                  ),
                  child: Text(
                    '${summary.adherencePercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: adherenceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (summary.scheduledCount == 0)
              Text(
                context.loc.t('noMedicinesScheduled'),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              )
            else
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.check_circle_outline,
                    label: 'Taken',
                    value: summary.takenCount.toString(),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    icon: Icons.cancel_outlined,
                    label: 'Missed',
                    value: summary.missedCount.toString(),
                    color: Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    icon: Icons.medication_outlined,
                    label: 'Total',
                    value: summary.scheduledCount.toString(),
                    color: Colors.blue,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
