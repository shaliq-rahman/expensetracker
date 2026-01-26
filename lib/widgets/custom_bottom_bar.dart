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
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 10,
      shadowColor: Colors.black12,
      child: SizedBox(
        height: 60.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(Icons.home_outlined, Icons.home, 0),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(Icons.pie_chart_outline, Icons.pie_chart, 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, int index) {
    final isSelected = selectedIndex == index;
    return IconButton(
      icon: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? Colors.black : Colors.grey,
        size: 28,
      ),
      onPressed: () => onItemTapped(index),
    );
  }
}
