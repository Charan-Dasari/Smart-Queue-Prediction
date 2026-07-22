import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Contact Support ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 32),
                  const SizedBox(height: 12),
                  const Text(
                    'Need Help?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Our support team is here to assist you.',
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('support@intelliq.com', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── FAQs ──
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              context,
              'How do I book an appointment?',
              'Go to the Home screen, tap "Book Appointment", select a service provider and service, choose a time slot, and confirm your booking.',
            ),
            _buildFaqItem(
              context,
              'How does the queue system work?',
              'After booking, you\'ll receive a token number. Track your position in real-time from the Home screen. You\'ll be notified when it\'s your turn.',
            ),
            _buildFaqItem(
              context,
              'Can I cancel an appointment?',
              'Yes! Go to your Appointment History, find the appointment you want to cancel, and tap the cancel option. Cancellations are free.',
            ),
            _buildFaqItem(
              context,
              'How do I change my password?',
              'Go to Profile > Change Password. Enter your current password and set a new one.',
            ),
            _buildFaqItem(
              context,
              'What are AI-powered time slots?',
              'IntelliQ uses AI to predict crowd levels and suggest the best time slots with minimal wait times.',
            ),
            _buildFaqItem(
              context,
              'Is my data safe?',
              'Yes, your data is encrypted and securely stored. We follow industry-standard security practices to protect your information.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor, height: 1.4),
          ),
        ],
      ),
    );
  }
}
