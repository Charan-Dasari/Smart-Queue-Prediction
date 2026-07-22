import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('About IntelliQ'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ── App Logo & Version ──
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'iQ',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'IntelliQ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Version 0.2.5',
              style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Stable Release',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.successColor),
              ),
            ),
            const SizedBox(height: 32),

            // ── Description ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'IntelliQ is an AI-powered smart queue management system designed to eliminate long waiting times at hospitals, banks, government offices, and educational institutions.\n\n'
                    'With features like intelligent appointment booking, real-time queue tracking, and AI-predicted optimal visit times, IntelliQ transforms the way people interact with service providers.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textMutedColor, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Features ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Key Features',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(Icons.auto_awesome, 'AI-Powered Scheduling', AppTheme.aiAccent),
                  _buildFeatureItem(Icons.access_time, 'Real-Time Queue Tracking', AppTheme.primaryColor),
                  _buildFeatureItem(Icons.notifications_active, 'Smart Notifications', AppTheme.warningColor),
                  _buildFeatureItem(Icons.analytics_outlined, 'Crowd Predictions', AppTheme.infoColor),
                  _buildFeatureItem(Icons.security, 'Secure & Private', AppTheme.successColor),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Tech Stack ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Built With',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _buildTechItem('Frontend', 'Flutter & Dart'),
                  _buildTechItem('Backend', 'ASP.NET Core Web API'),
                  _buildTechItem('Database', 'SQL Server'),
                  _buildTechItem('Authentication', 'JWT Bearer Tokens'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Copyright ──
            const Text(
              '© 2026 IntelliQ. All rights reserved.',
              style: TextStyle(fontSize: 12, color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 4),
            const Text(
              'Made with ❤️ for a smarter world',
              style: TextStyle(fontSize: 12, color: AppTheme.textLightColor),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textMutedColor),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMutedColor),
          ),
        ],
      ),
    );
  }
}
