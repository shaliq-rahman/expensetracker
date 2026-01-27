import 'package:flutter/material.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/screens/all_transactions_screen.dart';
import 'package:expense_tracker/widgets/custom_bottom_bar.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/screens/settings_screen.dart';

class TabsScreen extends StatefulWidget {
  const TabsScreen({super.key});

  @override
  State<TabsScreen> createState() => _TabsScreenState();
}

class _TabsScreenState extends State<TabsScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const AddTransactionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We need to pass the callback to HomeScreen so it can trigger the add screen too
    final List<Widget> pages = [
      HomeScreen(
        onAddExpense: () => _openAddTransaction(context),
        onViewAll: () => _onItemTapped(2), // Switch to History tab (index 2)
      ),
      const AnalyticsScreen(),
      const AllTransactionsScreen(),
      const SettingsScreen(),
    ];

    return GradientBackground(
      child: Scaffold(
        extendBody: true, // Allow body to flow behind bottom bar
        backgroundColor: Colors.transparent, // Transparent to show gradient
        body: pages[_selectedIndex],
        floatingActionButton: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFC6F432), Color(0xFFAEE010)], // Lime Green Gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC6F432).withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () => _openAddTransaction(context),
          elevation: 0, // Remove built-in elevation to use Container's shadow
          backgroundColor: Colors.transparent, // Transparent to show gradient
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Colors.black),
        ),
      ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: CustomBottomBar(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          onAddPressed: () => _openAddTransaction(context),
        ),
      ),
    );
  }
}
