import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF000000), // Pure Black
                  const Color(0xFF13180F), // Very Dark Lime/Black
                  const Color(0xFF000000), // Back to Black
                ]
              : [
                  const Color(0xFFFFFFFF), // Pure White
                  const Color(0xFFE4F0D5), // Soft Pale Lime/Grey
                  const Color(0xFFFFFFFF), // Back to White
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}
