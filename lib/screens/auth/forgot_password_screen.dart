import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/auth_notifier.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/pill_logo.dart';

/// Forgot Password screen - allows users to reset their password via email.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.loc.t('fillAllFields'))));
      return;
    }

    setState(() => _isLoading = true);

    final auth = context.read<AuthNotifier>();
    final success = await auth.sendPasswordResetEmail(email);

    setState(() => _isLoading = false);

    if (success) {
      setState(() => _emailSent = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.loc.t('passwordResetEmailSent')),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      if (mounted) {
        final msg =
            auth.lastErrorMessage ?? context.loc.t('resetPasswordError');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _resetForm() {
    setState(() {
      _emailSent = false;
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Pastel blobs
          const Positioned(
            top: -30,
            left: -20,
            child: _Blob(color: Color(0xFFE0F7FA), size: 160),
          ),
          const Positioned(
            top: 100,
            right: -30,
            child: _Blob(color: Color(0xFFFFEBEE), size: 180),
          ),
          const Positioned(
            bottom: -40,
            left: 30,
            child: _Blob(color: Color(0xFFE8EAF6), size: 150),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.arrow_back, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Logo + title
                  Column(
                    children: [
                      const PillLogoAnimated(
                        size: 80,
                        showBadgeCircle: true,
                        showHalo: true,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Reset Password',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.teal[800],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Content
                  if (!_emailSent) ...[
                    Text(
                      'Enter your email address and we\'ll send you a link to reset your password.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: context.loc.t('email'),
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) =>
                          _isLoading ? null : _handleSendReset(),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendReset,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.teal[400],
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(context.loc.t('sendReset')),
                      ),
                    ),
                  ] else ...[
                    // Success message
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.green[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green[700],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Check Your Email',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We\'ve sent a password reset link to ${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Click the link in the email to reset your password. The link will expire in 1 hour.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _resetForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          backgroundColor: Colors.teal[400],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset Another Account'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.loc.t('backToLogin')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final Color color;
  final double size;

  const _Blob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}
