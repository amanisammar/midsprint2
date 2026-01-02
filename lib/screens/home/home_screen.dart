import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_notifier.dart';
import '../../root_gate.dart';
import '../../features/medicines/edit_medicine_screen.dart';
import '../../features/medicines/medicine_details_screen.dart';
import '../../l10n/app_localizations.dart';
import '../today_medicine.dart';
import '../profile/profile_screen.dart';

/// HomeScreen for PillCare - main app screen with logout capability.
class HomeScreen extends StatelessWidget {
  final String role;
  final String? name;

  const HomeScreen({super.key, required this.role, this.name});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          titleSpacing: 0,
          title: Row(
            children: [
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.teal[100],
                child: Icon(
                  role == 'patient' ? Icons.healing : Icons.volunteer_activism,
                  color: Colors.teal[700],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name != null && name!.isNotEmpty
                          ? context.loc.t(
                              'welcomeName',
                              params: {'name': name!},
                            )
                          : context.loc.t('welcome'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.medication,
                          size: 16,
                          color: Colors.teal[700],
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.teal[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role == 'patient'
                                ? context.loc.t('patient')
                                : context.loc.t('family'),
                            style: TextStyle(
                              color: Colors.teal[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              tooltip: context.loc.t('profile'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              key: const Key('logoutIcon'),
              tooltip: context.loc.t('logout'),
              onPressed: () async {
                await context.read<AuthNotifier>().signOut();
                // Navigate to RootGate which will redirect to LoginScreen
                // ignore: use_build_context_synchronously
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const RootGate()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.black87,
            indicatorColor: Color(0xFF2EC4B6),
            tabs: [
              Tab(text: context.loc.t('today')),
              Tab(text: context.loc.t('allMedicines')),
            ],
          ),
        ),
        /*body: TabBarView(
          children: [
            _TodayTab(role: role, name: name, userEmail: user?.email),
            const _AllMedicinesTab(),
          ],
        ),*/
        body: TabBarView(
          children: [
            TodayMedicineTab(role: role, name: name, userEmail: user?.email),
            const _AllMedicinesTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: context.loc.t('addMedicine'),
          backgroundColor: const Color(0xFF2EC4B6),
          foregroundColor: Colors.white,
          onPressed: () => Navigator.of(context).pushNamed('/add-medicine'),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

/*
class _TodayTab extends StatelessWidget {
  final String role;
  final String? name;
  final String? userEmail;

  const _TodayTab({required this.role, this.name, this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal[300]!, Colors.teal[600]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.13),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                role == 'patient'
                    ? Icons.medication_liquid
                    : Icons.family_restroom,
                size: 44,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              name != null && name!.isNotEmpty
                  ? context.loc.t('welcomeName', params: {'name': name!})
                  : context.loc.t('welcome'),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (userEmail != null)
              Text(
                userEmail!,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
            const SizedBox(height: 40),
            Text(
              'Your medication management starts here!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
*/
class _AllMedicinesTab extends StatefulWidget {
  const _AllMedicinesTab();

  @override
  State<_AllMedicinesTab> createState() => _AllMedicinesTabState();
}

class _AllMedicinesTabState extends State<_AllMedicinesTab> {
  String _searchQuery = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Center(child: Text(context.loc.t('signInToView')));
    }

    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Column(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: _searchBar()),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text(context.loc.t('failedLoad')));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(child: Text(context.loc.t('noMedicines')));
              }

              final filtered = docs.where((doc) {
                final data = doc.data();
                final targetName = data['name'] as String? ?? '';
                final nameLower = targetName.toLowerCase();
                final queryLower = _searchQuery.toLowerCase();
                return _searchQuery.isEmpty || nameLower.contains(queryLower);
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Text(context.loc.t('noResults')));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data();
                  final name = data['name'] as String? ?? 'Unnamed';
                  final dosage = data['dosage'];
                  final unit = data['unit'] as String? ?? '';
                  final dosageText = dosage != null ? '$dosage $unit' : unit;
                  final times =
                      (data['timesOfDay'] as List?)?.cast<String>() ?? [];
                  final schedule = _formatSchedule(times);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Dismissible(
                      key: ValueKey(doc.id),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text(context.loc.t('deleteMedicine')),
                                content: Text(
                                  context.loc.t(
                                    'deleteConfirm',
                                    params: {'name': name},
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: Text(context.loc.t('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: Text(context.loc.t('delete')),
                                  ),
                                ],
                              ),
                            ) ??
                            false;
                      },
                      onDismissed: (_) async {
                        try {
                          await doc.reference.delete();
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$name" deleted')),
                          );
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              // ignore: use_build_context_synchronously
                              content: Text(context.loc.t('failedLoad')),
                            ),
                          );
                        }
                      },
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => MedicineDetailsScreen(
                                docId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: Container(
                              width: 44,
                              height: 44,
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
                                child: Icon(
                                  Icons.medication,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(dosageText),
                                const SizedBox(height: 4),
                                Text(
                                  schedule,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.black87,
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EditMedicineScreen(
                                      docId: doc.id,
                                      initialData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: context.loc.t('searchHint'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (value) => setState(() {
        _searchQuery = value;
      }),
    );
  }

  String _formatSchedule(List<String> times) {
    if (times.isEmpty) return context.loc.t('noSchedule');
    if (times.length == 1) return context.loc.t('onceDaily');
    if (times.length == 2) return context.loc.t('twiceDaily');
    return context.loc.t(
      'timesPerDay',
      params: {'count': times.length.toString()},
    );
  }
}
