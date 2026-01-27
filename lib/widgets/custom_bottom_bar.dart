import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onAddPressed;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), // Stronger shadow in dark mode
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Increased Blur
            child: Container(
              decoration: BoxDecoration(
                color: (Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor).withOpacity(isDark ? 0.6 : 0.7), // More transparent
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.5), // Subtle glass border
                  width: 0.5,
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _buildNavItem(context, Icons.home_filled, "Home", 0),
                      _buildNavItem(context, Icons.bar_chart_rounded, "Analytics", 1),
                      
                      // Spacing for FAB
                      const SizedBox(width: 48),
        
                      _buildNavItem(context, Icons.history, "History", 2), 
                      _buildNavItem(context, Icons.settings_outlined, "Settings", 3), 
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    // Use theme text color for selected (Black/White) and grey for unselected
    final color = isSelected ? Theme.of(context).iconTheme.color : Colors.grey[600];
    
    return GestureDetector(
      onTap: () => onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
