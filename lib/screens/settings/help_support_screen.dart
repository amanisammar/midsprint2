import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.question_answer_outlined, color: Colors.teal),
                  title: const Text('FAQs'),
                  subtitle: const Text('Frequently asked questions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showFAQs(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.teal),
                  title: const Text('Contact Support'),
                  subtitle: const Text('support@pillcare.app'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email: support@pillcare.app')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined, color: Colors.teal),
                  title: const Text('Report a Bug'),
                  subtitle: const Text('Help us improve'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bug report form will open here')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.chat_outlined, color: Colors.teal),
                  title: const Text('Live Chat'),
                  subtitle: const Text('Chat with our support team'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Live chat coming soon')),
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

  void _showFAQs(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Frequently Asked Questions'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _faqItem('How do I add a medicine?', 'Tap the + button on the home screen to add a new medicine.'),
              const SizedBox(height: 16),
              _faqItem('How do I edit a medicine?', 'Tap on the medicine card to view details, then tap Edit.'),
              const SizedBox(height: 16),
              _faqItem('Can I set reminders?', 'Yes! Enable notifications in the settings to get reminded when it\'s time to take your medicine.'),
              const SizedBox(height: 16),
              _faqItem('How is my data protected?', 'Your data is encrypted and stored securely. We never share your information without consent.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(answer, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
