import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/category.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final categoryTotals = expenseProvider.categoryTotals;
    final totalExpense = expenseProvider.totalExpense;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: categoryTotals.isEmpty
          ? const Center(
              child: Text(
                'No expenses to analyze yet.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sections: categoryTotals.entries.map((entry) {
                          final percentage = (entry.value / totalExpense) * 100;
                          return PieChartSectionData(
                            color: _getCategoryColor(entry.key),
                            value: entry.value,
                            title: '', // Hide title on chart for cleaner look
                            radius: 30,
                            badgeWidget: Text(
                              '${percentage.toInt()}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            badgePositionPercentageOffset: 1.5,
                          );
                        }).toList(),
                        sectionsSpace: 4,
                        centerSpaceRadius: 60,
                        centerSpaceColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Categories using Grid or List
                  // Design shows grid-like pill buttons with Amount
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.extent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 2.5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: categoryTotals.entries.map((entry) {
                         return Container(
                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                           decoration: BoxDecoration(
                             color: const Color(0xFFF6F6F6),
                             borderRadius: BorderRadius.circular(16),
                           ),
                           child: Row(
                             children: [
                               CircleAvatar(
                                 radius: 14,
                                 backgroundColor: _getCategoryColor(entry.key).withValues(alpha: 0.2),
                                 child: Icon(_getCategoryIcon(entry.key), size: 16, color: _getCategoryColor(entry.key)),
                               ),
                               const SizedBox(width: 12),
                               Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(
                                       entry.key.name,
                                       style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                       overflow: TextOverflow.ellipsis,
                                     ),
                                     Text(
                                       '\$${entry.value.toInt()}', // Simplified currency
                                       style: const TextStyle(fontSize: 12, color: Colors.grey),
                                     ),
                                   ],
                                 ),
                               )
                             ],
                           ),
                         );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Color _getCategoryColor(ExpenseCategory category) {
    // Return distinct colors for each category custom palette
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFFFDD835); // Yellow
      case ExpenseCategory.transport:
        return Colors.blueAccent;
      case ExpenseCategory.entertainment:
        return Colors.purpleAccent;
      case ExpenseCategory.bills:
        return Colors.redAccent;
      case ExpenseCategory.shopping:
        return Colors.pinkAccent;
      case ExpenseCategory.health:
        return Colors.teal;
      case ExpenseCategory.education:
        return Colors.indigo;
      case ExpenseCategory.salary:
        return Colors.green;
      case ExpenseCategory.investment:
        return Colors.deepOrange;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.fastfood;
      case ExpenseCategory.transport:
        return Icons.directions_bus;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.bills:
        return Icons.receipt;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.health:
        return Icons.local_hospital;
      case ExpenseCategory.education:
        return Icons.school;
      case ExpenseCategory.salary:
        return Icons.attach_money;
      case ExpenseCategory.investment:
        return Icons.trending_up;
      case ExpenseCategory.other:
        return Icons.category;
    }
  }
}
