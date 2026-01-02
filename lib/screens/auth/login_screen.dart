import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

import '../../auth/auth_notifier.dart';
import '../../auth/auth_status.dart';
import '../../root_gate.dart';
import '../../widgets/pill_logo.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _prefillEmail();

    // If already authenticated, skip login screen.
    final auth = context.read<AuthNotifier>();
    if (auth.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goHome());
    }
  }

  Future<void> _prefillEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('lastEmail');
    if (saved != null && saved.isNotEmpty) {
      _emailController.text = saved;
      // Move focus to password after the current frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _passwordFocus.requestFocus();
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastEmail', email);
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.t('fillAllFields'))));
      return;
    }

    final auth = context.read<AuthNotifier>();
    final success = await auth.signIn(email, password);

    if (!success && mounted) {
      final msg = auth.lastErrorMessage ?? context.loc.t('loginError');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    if (!mounted) return;

    await _saveEmail(email);

    // ✅ Explicit navigation — exactly as taught
    _goHome();
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RootGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticating =
        context.watch<AuthNotifier>().status == AuthStatus.authenticating;

    return Scaffold(
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
                        context.loc.t('welcomeBack'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2B2D31),
                            ),
                      ),
                      const SizedBox(height: 24),
                      _RoundedInput(
                        controller: _emailController,
                        hintText: context.loc.t('email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      _RoundedInput(
                        controller: _passwordController,
                        hintText: context.loc.t('password'),
                        obscureText: _obscurePassword,
                        focusNode: _passwordFocus,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _handleLogin(),
                        autofillHints: const [AutofillHints.password],
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: isAuthenticating ? null : _handleLogin,
                        child: isAuthenticating
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.loc.t('signIn')),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Color(0xFF2EC4B6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: Text(
                          context.loc.t('createAccount'),
                          style: const TextStyle(
                            color: Color(0xFF2B2D31),
                            fontWeight: FontWeight.w600,
                          ),
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
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffix;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const _RoundedInput({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffix,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF23C3AE), width: 1.5),
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;

  const _Blob({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
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
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );

    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: blob,
    );
  }
}
