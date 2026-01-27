import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
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
    final transactions = expenseProvider.getFilteredTransactions(_filterType, _selectedDate);

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent for gradient
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: false,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
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
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions for this period',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                // Show latest first
                final tx = transactions[transactions.length - 1 - index];
                final isIncome = tx.type == TransactionType.income;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Avatar / Icon
                        Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.transparent, // Removed background color
                            shape: BoxShape.circle,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(tx.category.iconPath),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Theme.of(context).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat.yMMMd().add_jm().format(tx.date),
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                            ],
                          ),
                        ),

                        // Amount
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(tx.amount)}',
                              style: TextStyle(
                                color: isIncome ? const Color(0xFF00C853) : Theme.of(context).textTheme.bodyLarge?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isIncome ? 'Received' : 'Spent',
                              style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
  
  Color _getCategoryColor(ExpenseCategory category) {
    // Return vibrant pastel/neon colors for background circles
    switch (category) {
      case ExpenseCategory.food:
        return const Color(0xFF00C853); // Bolt Food Greenish
      case ExpenseCategory.travel:
        return const Color(0xFFFF4081); // Pinkish
      case ExpenseCategory.entertainment:
        return const Color(0xFFAA00FF);
      case ExpenseCategory.shopping:
        return const Color(0xFF2962FF);
      case ExpenseCategory.salary:
        return const Color(0xFFC6F432); // Lime
      case ExpenseCategory.freelance:
        return const Color(0xFF00E5FF); // Cyan Accent
      case ExpenseCategory.savings:
        return const Color(0xFFFFD740); // Amber Accent
      default:
        return Colors.grey[800]!;
    }
  }
}
