import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class MedicineDetailsScreen extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;

  const MedicineDetailsScreen({
    super.key,
    required this.docId,
    required this.data,
  });

  String _formatList(List<String> items, AppLocalizations loc) {
    if (items.isEmpty) return loc.t('noResults');
    return items.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final name = data['name'] as String? ?? loc.t('medicineName');
    final dosage = data['dosage'];
    final unit = data['unit'] as String? ?? '';
    final dosageText = dosage != null ? '$dosage $unit' : unit;
    final days = (data['days'] as List?)?.cast<String>() ?? [];
    final times = (data['timesOfDay'] as List?)?.cast<String>() ?? [];
    final localizedDays = days.map((d) => _localizedDay(loc, d)).toList();
    final localizedTimes = times.map((t) => _localizedTime(loc, t)).toList();
    final startDate = data['startDate'];
    final startDateString = _formatDate(startDate, loc);
    final endDate = data['endDate'];
    final endDateString = _formatDate(endDate, loc);
    final notes = data['notes'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          loc.t('medicineDetails'),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            _detailCard(
              title: name,
              subtitle: dosageText,
              leading: _pillIcon(),
            ),
            const SizedBox(height: 12),
            _detailCard(
              title: loc.t('daysOfWeek'),
              subtitle: _formatList(localizedDays, loc),
            ),
            const SizedBox(height: 12),
            _detailCard(
              title: loc.t('timesOfDay'),
              subtitle: _formatList(localizedTimes, loc),
            ),
            const SizedBox(height: 12),
            _detailCard(title: loc.t('startDate'), subtitle: startDateString),
            const SizedBox(height: 12),
            _detailCard(title: loc.t('endDate'), subtitle: endDateString),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _detailCard(title: loc.t('notesOptional'), subtitle: notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required String subtitle,
    Widget? leading,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFCCF2EA),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.medication, color: Colors.white, size: 26),
      ),
    );
  }

  String _formatDate(dynamic value, AppLocalizations loc) {
    if (value == null) return loc.t('startDateNotSet');
    if (value is DateTime) {
      return value.toLocal().toString().split(' ').first;
    }
    if (value is Timestamp) {
      return value.toDate().toLocal().toString().split(' ').first;
    }
    return value.toString();
  }

  String _localizedDay(AppLocalizations loc, String day) {
    switch (day.toLowerCase()) {
      case 'sunday':
        return loc.t('sunday');
      case 'monday':
        return loc.t('monday');
      case 'tuesday':
        return loc.t('tuesday');
      case 'wednesday':
        return loc.t('wednesday');
      case 'thursday':
        return loc.t('thursday');
      case 'friday':
        return loc.t('friday');
      case 'saturday':
        return loc.t('saturday');
      default:
        return day;
    }
  }

  String _localizedTime(AppLocalizations loc, String time) {
    switch (time.toLowerCase()) {
      case 'morning':
        return loc.t('morning');
      case 'noon':
        return loc.t('noon');
      case 'evening':
        return loc.t('evening');
      case 'night':
        return loc.t('night');
      default:
        return time;
    }
  }
}
