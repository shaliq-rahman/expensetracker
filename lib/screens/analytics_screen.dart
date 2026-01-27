import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int touchedIndex = -1;
  String _filterType = 'Month'; // 'Day', 'Month', 'Year'
  DateTime _selectedDate = DateTime.now();

  void _updateFilter(String type) {
    setState(() {
      _filterType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    
    // Filter transactions logic (similar to Home Screen but local for Analytics layout ref)
    // Actually ExpenseProvider has a method for this, let's use it to get filtered transactions
    // and then manually compute category totals from those specific transactions
    // because expenseProvider.categoryTotals is a getter for ALL transactions usually or depends on how it's implemented.
    // Checking previous knowledge: expenseProvider.categoryTotals might be global. 
    // Let's check ExpenseProvider usage in HomeScreen. 
    // HomeScreen uses: provider.getFilteredTransactions(_filterType, _selectedDate);
    // Analytics needs category totals for the PIE CHART. 
    // If I use getFilteredTransactions, I need to group them by category myself or add a helper in Provider.
    // For now, I will calculate it here to avoid modifying Provider if not needed, or better yet, verify Provider capabilities.
    
    // Wait, let's look at build method again. 
    // It calls `final categoryTotals = expenseProvider.categoryTotals;` 
    // `categoryTotals` likely returns totals for ALL transactions. 
    // I need totals for FILTERED transactions.
    
    final filteredTransactions = expenseProvider.getFilteredTransactions(_filterType, _selectedDate);
    final Map<ExpenseCategory, double> filteredTotals = {};
    double filteredTotalExpense = 0;

    for (var tx in filteredTransactions) {
      if (tx.type == TransactionType.expense) {
        filteredTotals.update(tx.category, (value) => value + tx.amount, ifAbsent: () => tx.amount);
        filteredTotalExpense += tx.amount;
      }
    }
    
    // Use these filtered values instead of global ones
    final categoryTotals = filteredTotals;
    final totalExpense = filteredTotalExpense;

    // Filter out categories with 0 expense to avoid cluttering the chart
    final nonZeroCategories = categoryTotals.entries.where((e) => e.value > 0).toList();
    // Sort by value descending
    nonZeroCategories.sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for gradient
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 18),
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        actions: [
            // Filter dropdown in AppBar
            PopupMenuButton<String>(
              onSelected: _updateFilter,
              itemBuilder: (BuildContext context) {
                return {'Day', 'Month', 'Year'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _filterType,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, color: Theme.of(context).iconTheme.color, size: 16),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: nonZeroCategories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text(
                    'No expenses for this period.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  // Interactive Pie Chart
                  SizedBox(
                    height: 220, // Reduced height
                    child: PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                touchedIndex = -1;
                                return;
                              }
                              touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 6, // Increased space for depth
                        centerSpaceRadius: 40, // Reduced center space
                        centerSpaceColor: Theme.of(context).scaffoldBackgroundColor,
                        sections: List.generate(nonZeroCategories.length, (i) {
                          final entry = nonZeroCategories[i];
                          final isTouched = i == touchedIndex;
                          final fontSize = isTouched ? 18.0 : 12.0;
                          final radius = isTouched ? 60.0 : 50.0; // Reduced thickness
                          final percentage = (entry.value / totalExpense) * 100;
                          
                          return PieChartSectionData(
                            color: _getCategoryColor(entry.key),
                            value: entry.value,
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: radius,
                            titleStyle: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                            ),
                            badgeWidget: isTouched ? _buildBadge(entry.key) : null,
                            badgePositionPercentageOffset: 1.1,
                            // Gradient to simulate 3D (Future enhancement: FLChart doesn't support direct gradients on sections easily yet without shader mask, 
                            // sticking to solid bold colors with shadows in title for now, but using distinct palette).
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Breakdown',
                        style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Category List with Large Icons
                  ListView.builder(
                    itemCount: nonZeroCategories.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20), // Adjusted padding (removed vertical 10 to rely on margins)
                    itemBuilder: (context, index) {
                      final entry = nonZeroCategories[index];
                      final category = entry.key;
                      final amount = entry.value;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16), // Match Home Screen margin
                        padding: const EdgeInsets.all(16), // Match Home Screen padding
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            // Large Icon Container (Matching Home Screen Size & Shape)
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Colors.transparent, // Removed background color
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Image.asset(
                                  category.iconPath,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.name,
                                    style: TextStyle(
                                      fontFamily: 'Outfit', // Match Home Screen Font
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                      fontSize: 16, // Match Home Screen Size (was 18)
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(amount / totalExpense * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: Colors.grey[600], // Match Home Screen Grey
                                      fontSize: 13, // Match Home Screen Size (was 14)
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount),
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color,
                                fontSize: 16, // Match Home Screen Size (was 18)
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildBadge(ExpenseCategory category) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent, // Removed background color
        shape: BoxShape.circle,
      ),
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: Image.asset(category.iconPath, width: 20),
      ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFFAB00); // Amber 800 - Vibrant Gold
      case ExpenseCategory.travel:
        return const Color(0xFF00E5FF); // Cyan Accent 400 - Neon Blue
      case ExpenseCategory.entertainment:
        return const Color(0xFFD500F9); // Purple Accent 400 - Neon Purple
      case ExpenseCategory.bills:
        return const Color(0xFFFF1744); // Red Accent 400 - Neon Red
      case ExpenseCategory.shopping:
        return const Color(0xFF651FFF); // Deep Purple Accent 400
      case ExpenseCategory.health:
        return const Color(0xFF00E676); // Green Accent 400
      case ExpenseCategory.education:
        return const Color(0xFF2979FF); // Blue Accent 400
      case ExpenseCategory.salary:
        return const Color(0xFF76FF03); // Light Green Accent 400
      case ExpenseCategory.freelance:
        return const Color(0xFF1DE9B6); // Teal Accent 400
      case ExpenseCategory.savings:
        return const Color(0xFFFFD740); // Amber Accent 200
      case ExpenseCategory.investment:
        return const Color(0xFFFF6D00); // Orange Accent 400
      case ExpenseCategory.other:
        return const Color(0xFFB0BEC5); // Blue Grey 200
    }
  }
}
