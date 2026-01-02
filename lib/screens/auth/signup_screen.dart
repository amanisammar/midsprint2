import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_status.dart';
import '../../widgets/pill_logo.dart';
import '../../l10n/app_localizations.dart';
import '../onboarding/role_selection_screen.dart';

/// Signup screen for PillCare - creates new user accounts.
class SignupScreen extends StatefulWidget {
  static const routeName = '/signup';

  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isLoading = false;
  DateTime? _birthDate;
  final DateFormat _birthDateFormatter = DateFormat('yyyy-MM-dd');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.t('fillAllFields'))));
      return;
    }

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('pleaseSelectBirthDate'))),
      );
      return;
    }

    if (_birthDate!.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('birthDateFutureError'))),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.loc.t('passwordTooShort'))),
      );
      return;
    }

    final auth = context.read<AuthNotifier>();
    setState(() => _isLoading = true);

    final success = await auth.signUp(
      name,
      email,
      password,
      birthDate: _birthDate!,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastEmail', email);
      if (!mounted) return;
      // Immediately take new users to role selection and block back navigation
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (route) => false,
      );
    } else {
      if (!mounted) return;
      final msg =
          context.read<AuthNotifier>().lastErrorMessage ??
          context.loc.t('signupError');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  DateTime? _parseBirthDate(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return null;

    final formats = <DateFormat>[
      DateFormat('yyyy-MM-dd'),
      DateFormat('yyyy/MM/dd'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('MM-dd-yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('dd-MM-yyyy'),
    ];

    for (final format in formats) {
      try {
        final parsed = format.parseStrict(input);
        return DateTime(parsed.year, parsed.month, parsed.day);
      } catch (_) {
        // Continue trying other formats
      }
    }

    final isoParsed = DateTime.tryParse(input);
    return isoParsed != null
        ? DateTime(isoParsed.year, isoParsed.month, isoParsed.day)
        : null;
  }

  void _onBirthDateChanged(String value) {
    final parsed = _parseBirthDate(value);
    setState(() => _birthDate = parsed);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 30, now.month, now.day);
    final firstDate = DateTime(now.year - 120);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: context.loc.t('selectBirthDate'),
    );

    if (picked != null) {
      final textValue = _birthDateFormatter.format(picked);
      _birthDateController.text = textValue;
      _onBirthDateChanged(textValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthNotifier>().status;
    final isBusy = _isLoading || authStatus == AuthStatus.authenticating;
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    final bottomSafeInset = mediaQuery.viewPadding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF9F7F4),
      body: Stack(
        children: [
          const _Blob(color: Color(0xFFBFE6FF), size: 220, top: -60, left: -70),
          const _Blob(
            color: Color(0xFFFFD9D6),
            size: 200,
            bottom: -40,
            left: 40,
          ),
          const _Blob(
            color: Color(0xFFCCF2EA),
            size: 240,
            bottom: -70,
            right: -60,
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      const Center(
                        child: PillLogoAnimated(
                          size: 90,
                          showHalo: false,
                          showBadgeCircle: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'PillCare',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF24948C),
                              ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        context.loc.t('joinUs'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B2D31),
                            ),
                      ),
                      const SizedBox(height: 24),
                      _RoundedInput(
                        controller: _nameController,
                        hintText: context.loc.t('name'),
                        enabled: !isBusy,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 14),
                      _RoundedInput(
                        controller: _emailController,
                        hintText: context.loc.t('email'),
                        enabled: !isBusy,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _RoundedInput(
                        controller: _passwordController,
                        hintText: context.loc.t('password'),
                        enabled: !isBusy,
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      _BirthDateInput(
                        controller: _birthDateController,
                        enabled: !isBusy,
                        onChanged: _onBirthDateChanged,
                        onPickDate: _pickBirthDate,
                        isValid: _birthDate != null ||
                            _birthDateController.text.trim().isEmpty,
                        label: context.loc.t('birthDate'),
                      ),
                      const SizedBox(height: 22),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: EdgeInsets.only(
                          bottom: keyboardInset + bottomSafeInset + 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            isBusy
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ElevatedButton(
                                    key: const Key('signupButton'),
                                    onPressed: _handleSignUp,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      backgroundColor: const Color(0xFF23C3AE),
                                      foregroundColor: Colors.white,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    child: Text(context.loc.t('signUp')),
                                  ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.loc.t('haveAccount'),
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                TextButton(
                                  key: const Key('loginLink'),
                                  onPressed: isBusy
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: Text(
                                    context.loc.t('signIn'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2B2D31),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _RoundedInput({
    required this.controller,
    required this.hintText,
    required this.enabled,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFF23C3AE), width: 1.5),
        ),
      ),
    );
  }
}

class _BirthDateInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPickDate;
  final bool isValid;
  final String label;

  const _BirthDateInput({
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onPickDate,
    required this.isValid,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.datetime,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            helperText: 'Example: 1970-05-14',
            helperStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF23C3AE)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month_rounded),
              color: const Color(0xFF23C3AE),
              tooltip: context.loc.t('selectBirthDate'),
              onPressed: enabled ? onPickDate : null,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
              borderSide: BorderSide(color: Color(0xFF23C3AE), width: 1.5),
            ),
            errorText: isValid ? null : context.loc.t('pleaseSelectBirthDate'),
          ),
        ),
      ],
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

  const _Blob({
    required this.color,
    required this.size,
    this.top,
    this.left,
    this.right,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final blob = Container(
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
    );

    if (top != null || left != null || right != null || bottom != null) {
      return Positioned(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: blob,
      );
    }

    return blob;
  }
}
