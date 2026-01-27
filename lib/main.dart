import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/widgets/custom_bottom_bar.dart';
import 'package:expense_tracker/screens/all_transactions_screen.dart';

import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Expense Tracker',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFC6F432), // Lime Green
              secondary: Color(0xFFC6F432),
              surface: Color(0xFFF5F5F5), // Light Grey Surface for Cards
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, // Transparent for gradient
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.black),
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFFF5F5F5), // Light Grey for Cards
          ),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF050505), // Deep Black
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFC6F432), // Lime Green
              secondary: Color(0xFFC6F432),
              surface: Color(0xFF161618), // Dark Grey Surface
            ),
            textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent, // Transparent for gradient
              elevation: 0,
              centerTitle: false,
              iconTheme: IconThemeData(color: Colors.white),
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: const Color(0xFF161618), // Dark Grey for Cards
          ),
          home: const TabsScreen(),
        );
      },
    );
  }
}

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
      const Scaffold(
        backgroundColor: Colors.transparent, 
        body: Center(child: Text("Settings Placeholder", style: TextStyle(color: Colors.white)))
      ),
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
