import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/screens/home_screen.dart';
import 'package:expense_tracker/screens/analytics_screen.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/widgets/custom_bottom_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Expense Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF6F6F6),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFDD835),
            primary: const Color(0xFFFDD835),
            secondary: Colors.black,
            surface: Colors.white,
          ),
          textTheme: GoogleFonts.outfitTextTheme().apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFF6F6F6),
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

        ),
        home: const TabsScreen(),
      ),
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
      HomeScreen(onAddExpense: () => _openAddTransaction(context)),
      const AnalyticsScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6), // Match theme background
      body: pages[_selectedIndex],
      floatingActionButton: SizedBox(
        height: 70,
        width: 70,
        child: FloatingActionButton(
          onPressed: () => _openAddTransaction(context),
          elevation: 5,
          backgroundColor: const Color(0xFFFDD835),
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
    );
  }
}
