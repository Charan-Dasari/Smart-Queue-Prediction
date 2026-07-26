import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return UserThemeWrapper(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('About IntelliQ'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── App Logo & Version ──
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'iQ',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'IntelliQ Platform',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: theme.textTheme.bodyLarge?.color,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Version 0.2.5 • Enterprise Edition',
                style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '● Stable Production Build',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.successColor),
                ),
              ),
              const SizedBox(height: 32),

              // ── Description ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mission Overview',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'IntelliQ is an AI-driven smart queue management ecosystem designed to eliminate wait-time uncertainty across healthcare, banking, education, and public sector services.\n\n'
                      'Through real-time telemetry, predictive ML models, and digital pass orchestration, IntelliQ connects service providers with customers seamlessly.',
                      style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Features ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Platform Capabilities',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 14),
                    _buildFeatureItem(context, Icons.auto_awesome, 'AI-Powered Smart Scheduling', AppTheme.aiAccent),
                    _buildFeatureItem(context, Icons.access_time_rounded, 'Real-Time Queue Telemetry', AppTheme.primaryColor),
                    _buildFeatureItem(context, Icons.notifications_active_rounded, 'Proactive Mobile Notifications', AppTheme.warningColor),
                    _buildFeatureItem(context, Icons.analytics_rounded, 'Crowd Load Forecasting', AppTheme.infoColor),
                    _buildFeatureItem(context, Icons.security_rounded, 'Zero-Trust Data Protection', AppTheme.successColor),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Tech Stack ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Technology Stack',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color),
                    ),
                    const SizedBox(height: 14),
                    _buildTechItem(context, 'Frontend', 'Flutter & Dart (Cross-Platform)'),
                    _buildTechItem(context, 'Backend', 'ASP.NET Core Web API 9.0'),
                    _buildTechItem(context, 'Database', 'SQL Server & Entity Framework Core'),
                    _buildTechItem(context, 'Authentication', 'JWT Bearer & Role-Based Access'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Copyright ──
              Text(
                '© 2026 IntelliQ Inc. All rights reserved.',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.hintColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Engineered with precision for seamless queue experiences',
                style: TextStyle(fontSize: 12, color: theme.hintColor),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text, Color color) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            text,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
          ),
        ],
      ),
    );
  }

  Widget _buildTechItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
            ),
          ),
        ],
      ),
    );
  }
}

