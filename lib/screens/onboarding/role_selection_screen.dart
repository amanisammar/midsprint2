import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_notifier.dart';
import '../../widgets/pill_logo.dart';
import '../../root_gate.dart';

/// Role selection screen - allows user to choose between patient or family member.
class RoleSelectionScreen extends StatefulWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;

  Future<void> _handleContinue() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthNotifier>();
    try {
      await auth.updateUserRole(_selectedRole!);
      // Proactively navigate back to RootGate so it can route to Home.
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RootGate()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save role')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pastel blobs per reference design
          const _Blob(color: Color(0xFFE0F7FA), size: 160, top: -30, left: -20),
          const _Blob(color: Color(0xFFFFEBEE), size: 180, top: 100, right: -30),
          const _Blob(color: Color(0xFFE8EAF6), size: 150, bottom: -40, left: 30),
          SafeArea(
            child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                // Logo + title
                Column(
                  children: [
                      const PillLogoAnimated(size: 80, showBadgeCircle: true, showHalo: true),
                    const SizedBox(height: 12),
                    Text(
                      'PillCare',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.teal[800],
                          ),
                    ),
                    Text(
                      'Helping you and your family stay on track',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.teal[600],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Who are you?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF334155),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                _KawaiiRoleCard(
                  key: const Key('patientCard'),
                  title: 'I am the patient',
                  subtitle: 'I am the one who takes the medicines.',
                  icon: Icons.person,
                  isSelected: _selectedRole == 'patient',
                  onTap: _isLoading ? null : () => setState(() => _selectedRole = 'patient'),
                ),
                const SizedBox(height: 16),
                _KawaiiRoleCard(
                  key: const Key('familyCard'),
                  title: 'I am a family member',
                  subtitle: 'I help someone take their medicines.',
                  icon: Icons.family_restroom,
                  isSelected: _selectedRole == 'family',
                  onTap: _isLoading ? null : () => setState(() => _selectedRole = 'family'),
                ),
                const Spacer(),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('continueButton'),
                          onPressed: _selectedRole == null ? null : _handleContinue,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            backgroundColor: Colors.teal[400],
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _KawaiiRoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _KawaiiRoleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFFFFFFF).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? Colors.teal.shade400 : Colors.transparent,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 40, color: isSelected ? Colors.teal[600] : Colors.teal[300]),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(Icons.check, size: 18, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  const _Blob({required this.color, required this.size, this.top, this.left, this.right, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size * 0.35),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
    );
  }
}
