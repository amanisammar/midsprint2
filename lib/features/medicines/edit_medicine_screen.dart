import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class EditMedicineScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> initialData;

  const EditMedicineScreen({
    super.key,
    required this.docId,
    required this.initialData,
  });

  @override
  State<EditMedicineScreen> createState() => _EditMedicineScreenState();
}

class _EditMedicineScreenState extends State<EditMedicineScreen> {
  late TextEditingController _nameController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  late List<String> _selectedTimes;
  late List<String> _selectedDays;
  final List<String> _days = const [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  String _dosageUnit = 'pill';
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime _endDate = DateUtils.dateOnly(DateTime.now());

  final List<String> _commonMedicines = const [
    'Acamol',
    'Nurofen',
    'Optalgin',
    'Ibuprofen',
    'Kalgaron',
    'Acamoli',
    'Simvastatin',
    'Losec',
    'Zantac',
    'Tegretol',
    'Adex',
  ];

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    final dosage = widget.initialData['dosage'];
    _dosageController = TextEditingController(
      text: dosage != null ? dosage.toString() : '',
    );
    _notesController = TextEditingController(
      text: widget.initialData['notes'] as String? ?? '',
    );

    _selectedTimes =
        (widget.initialData['timesOfDay'] as List?)?.cast<String>() ?? [];
    _selectedDays = (widget.initialData['days'] as List?)?.cast<String>() ?? [];
    _dosageUnit = widget.initialData['unit'] as String? ?? 'pill';

    final startTimestamp = widget.initialData['startDate'];
    if (startTimestamp is Timestamp) {
      _startDate = DateUtils.dateOnly(startTimestamp.toDate());
    } else if (startTimestamp is DateTime) {
      _startDate = DateUtils.dateOnly(startTimestamp);
    }

    final endTimestamp = widget.initialData['endDate'];
    if (endTimestamp is Timestamp) {
      _endDate = DateUtils.dateOnly(endTimestamp.toDate());
    } else if (endTimestamp is DateTime) {
      _endDate = DateUtils.dateOnly(endTimestamp);
    } else {
      _endDate = _startDate;
    }
    if (_endDate.isBefore(_startDate)) {
      _endDate = _startDate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final name = widget.initialData['name'] as String? ?? '';
    _nameController.text = name;
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTime(String time) {
    setState(() {
      _selectedTimes.contains(time)
          ? _selectedTimes.remove(time)
          : _selectedTimes.add(time);
    });
  }

  void _toggleDay(String day) {
    setState(() {
      _selectedDays.contains(day)
          ? _selectedDays.remove(day)
          : _selectedDays.add(day);
    });
  }

  Future<void> _pickStartDate() async {
    final allowedWeekdays = _allowedWeekdays;
    if (allowedWeekdays.isEmpty) {
      _showSelectDaysMessage();
      return;
    }

    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1);
    final lastDate = DateTime(now.year + 5);
    final initialDate = _initialPickerDate(
      _startDate,
      allowedWeekdays,
      firstDate,
      lastDate,
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (day) => allowedWeekdays.contains(day.weekday),
    );
    if (picked != null) {
      setState(() {
        _startDate = DateUtils.dateOnly(picked);
        final updatedAllowedWeekdays = _allowedWeekdays;
        if (_endDate.isBefore(_startDate) ||
            !updatedAllowedWeekdays.contains(_endDate.weekday)) {
          _endDate = _findNextAllowedDate(
            _startDate,
            updatedAllowedWeekdays,
            firstDate,
            lastDate,
          );
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final allowedWeekdays = _allowedWeekdays;
    if (allowedWeekdays.isEmpty) {
      _showSelectDaysMessage();
      return;
    }

    final now = DateTime.now();
    final firstDate = DateUtils.dateOnly(_startDate);
    final lastDate = DateTime(now.year + 5);
    final initialDate = _initialPickerDate(
      _endDate.isBefore(firstDate) ? firstDate : _endDate,
      allowedWeekdays,
      firstDate,
      lastDate,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: (day) =>
          allowedWeekdays.contains(day.weekday) && !day.isBefore(firstDate),
    );

    if (picked != null) {
      setState(() {
        _endDate = DateUtils.dateOnly(picked);
      });
    }
  }

  void _showSelectDaysMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.loc.t('selectDaysFirst'))));
  }

  Set<int> get _allowedWeekdays =>
      _selectedDays.map(_weekdayFromDay).whereType<int>().toSet();

  int? _weekdayFromDay(String day) {
    switch (day.toLowerCase()) {
      case 'monday':
        return DateTime.monday;
      case 'tuesday':
        return DateTime.tuesday;
      case 'wednesday':
        return DateTime.wednesday;
      case 'thursday':
        return DateTime.thursday;
      case 'friday':
        return DateTime.friday;
      case 'saturday':
        return DateTime.saturday;
      case 'sunday':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  DateTime _initialPickerDate(
    DateTime preferred,
    Set<int> allowedWeekdays,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    var candidate = DateUtils.dateOnly(preferred);
    if (candidate.isBefore(firstDate)) {
      candidate = firstDate;
    }
    if (candidate.isAfter(lastDate)) {
      candidate = lastDate;
    }
    if (!allowedWeekdays.contains(candidate.weekday)) {
      candidate = _findNextAllowedDate(
        candidate,
        allowedWeekdays,
        firstDate,
        lastDate,
      );
    }
    return candidate;
  }

  DateTime _findNextAllowedDate(
    DateTime start,
    Set<int> allowedWeekdays,
    DateTime firstDate,
    DateTime lastDate,
  ) {
    var date = DateUtils.dateOnly(start);
    for (var i = 0; i < 7; i++) {
      if (!date.isAfter(lastDate) && allowedWeekdays.contains(date.weekday)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    date = DateUtils.dateOnly(start);
    for (var i = 0; i < 7; i++) {
      if (!date.isBefore(firstDate) && allowedWeekdays.contains(date.weekday)) {
        return date;
      }
      date = date.subtract(const Duration(days: 1));
    }
    return DateUtils.dateOnly(start.isBefore(firstDate) ? firstDate : lastDate);
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ').first;
  }

  Future<void> _save() async {
    final loc = context.loc;
    final name = _nameController.text.trim();
    final dosageText = _dosageController.text.trim();

    if (name.isEmpty ||
        dosageText.isEmpty ||
        _selectedDays.isEmpty ||
        _selectedTimes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('pleaseFill'))));
      return;
    }

    final dosage = double.tryParse(dosageText);
    if (dosage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('dosageNumber'))));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('pleaseSignIn'))));
      return;
    }

    final data = {
      'name': name,
      'dosage': dosage,
      'unit': _dosageUnit,
      'days': _selectedDays,
      'timesOfDay': _selectedTimes,
      'startDate': Timestamp.fromDate(_startDate),
      'endDate': Timestamp.fromDate(_endDate),
      'notes': _notesController.text.trim(),
      'updatedAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(widget.docId)
          .update(data);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('medicineUpdated'))));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.t('failedUpdate'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          loc.t('editMedicine'),
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                _medicineNameField(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _inputField(
                        label: loc.t('dosageAmount'),
                        icon: Icons.science,
                        controller: _dosageController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _dosageUnit,
                      items: [
                        DropdownMenuItem(
                          value: 'pill',
                          child: Text(loc.t('pill')),
                        ),
                        DropdownMenuItem(value: 'ml', child: Text(loc.t('ml'))),
                        DropdownMenuItem(value: 'mg', child: Text(loc.t('mg'))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _dosageUnit = value);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text(
                  loc.t('daysOfWeek'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _days
                      .map(
                        (day) => FilterChip(
                          label: Text(_localizedDay(loc, day)),
                          selected: _selectedDays.contains(day),
                          onSelected: (_) => _toggleDay(day),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),

                Text(
                  loc.t('selectTime'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _timeTile(loc.t('morning'), Icons.wb_sunny, 'morning'),
                    _timeTile(loc.t('noon'), Icons.sunny, 'noon'),
                    _timeTile(loc.t('evening'), Icons.nights_stay, 'evening'),
                    _timeTile(
                      loc.t('night'),
                      CupertinoIcons.moon_stars_fill,
                      'night',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _inputField(
                  label: loc.t('notesOptional'),
                  icon: Icons.notes,
                  controller: _notesController,
                  maxLines: 2,
                ),

                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${loc.t('startDate')}: ${_formatDate(_startDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickStartDate,
                      child: Text(loc.t('startDate')),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${loc.t('endDate')}: ${_formatDate(_endDate)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: _pickEndDate,
                      child: Text(loc.t('endDate')),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2EC4B6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    loc.t('saveChanges'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _timeTile(String label, IconData icon, String value) {
    final selected = _selectedTimes.contains(value);

    Color iconColor;
    Color selectedBg;

    switch (value) {
      case 'morning':
        iconColor = const Color.fromARGB(255, 255, 230, 7);
        selectedBg = const Color(0xFFFFF3CD);
        break;
      case 'noon':
        iconColor = const Color.fromARGB(255, 249, 176, 7);
        selectedBg = const Color(0xFFFFF8E1);
        break;
      case 'evening':
        iconColor = const Color.fromARGB(255, 187, 106, 0);
        selectedBg = const Color(0xFFFFE0B2);
        break;
      case 'night':
        iconColor = const Color.fromARGB(255, 28, 36, 127);
        selectedBg = const Color(0xFFE8EAF6);
        break;
      default:
        iconColor = Colors.grey;
        selectedBg = Colors.white;
    }

    return GestureDetector(
      onTap: () => _toggleTime(value),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? iconColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 4),
            Text(
              _timeRangeText(value),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  String _timeRangeText(String value) {
    switch (value) {
      case 'morning':
        return '05:00 - 11:59';
      case 'noon':
        return '12:00 - 16:59';
      case 'evening':
        return '17:00 - 20:59';
      case 'night':
        return '21:00 - 04:59';
      default:
        return '';
    }
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

  Widget _medicineNameField() {
    final optionsList = _commonMedicines;

    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _nameController.text),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.toLowerCase();
        if (query.isEmpty) return optionsList;
        return optionsList.where(
          (option) => option.toLowerCase().contains(query),
        );
      },
      onSelected: (selection) {
        setState(() {
          _nameController.text = selection;
          _nameController.selection = TextSelection.fromPosition(
            TextPosition(offset: selection.length),
          );
        });
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        _nameController = textController;
        return TextField(
          controller: textController,
          focusNode: focusNode,
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: context.loc.t('medicineName'),
            prefixIcon: const Icon(Icons.medication),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
