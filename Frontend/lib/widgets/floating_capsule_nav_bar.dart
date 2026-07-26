import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/theme.dart';

class FloatingCapsuleNavBar extends StatelessWidget {
  final int currentIndex;

  const FloatingCapsuleNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 480;

    return Container(
      height: isNarrow ? 56 : 64,
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 8 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1730) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2645) : AppTheme.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildCapsuleItem(context, 0, Icons.grid_view_rounded, 'Explore', () {
            if (currentIndex != 0) context.go('/home');
          }, isNarrow),
          _buildCapsuleItem(context, 1, Icons.calendar_month_rounded, 'Bookings', () {
            if (currentIndex != 1) context.push('/history');
          }, isNarrow),
          _buildCapsuleItem(context, 2, Icons.radar_rounded, 'Track', () {
            if (currentIndex != 2) context.push('/my-tokens');
          }, isNarrow),
          _buildCapsuleItem(context, 3, Icons.person_rounded, 'Profile', () {
            if (currentIndex != 3) context.push('/profile');
          }, isNarrow),
        ],
      ),
    );
  }

  Widget _buildCapsuleItem(BuildContext context, int index, IconData icon, String label, VoidCallback onTap, bool isNarrow) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isNarrow ? (isSelected ? 10 : 8) : 14,
          vertical: isNarrow ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isNarrow ? 18 : 20,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMutedColor,
            ),
            if (isSelected) ...[
              SizedBox(width: isNarrow ? 4 : 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: isNarrow ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
