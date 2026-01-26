import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';

import 'package:expense_tracker/models/category.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback onAddExpense; // Callback to open Add screen

  const HomeScreen({super.key, required this.onAddExpense});

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencyFormat = NumberFormat.simpleCurrency(name: 'INR'); // Using INR as per design

    // Calculate "Budget" progress (Mock logic for now)
    final totalSpent = expenseProvider.totalExpense;
    const double budget = 25000;
    final double progress = (totalSpent / budget).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 20),
            const SizedBox(width: 8),
            const Text('Home'),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFDD835).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.person_outline, color: Colors.black, size: 24),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // This Month Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'This Month',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const Icon(Icons.visibility_outlined, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: currencyFormat.format(totalSpent),
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                ),
                          ),
                          TextSpan(
                            text: ' spent',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress > 0.8 ? Colors.red : const Color(0xFFFDD835),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Budget: ${currencyFormat.format(budget)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onAddExpense,
                            icon: const Icon(Icons.download, size: 18), // Icon similar to design
                            label: const Text('Add Expense'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.bar_chart, size: 18),
                            label: const Text('Set Budget'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.grey),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Transaction List
              _buildSectionHeader('Today'),
              _buildTransactionList(context, expenseProvider, 'Today'),
              const SizedBox(height: 20),
              _buildSectionHeader('Yesterday'),
              _buildTransactionList(context, expenseProvider, 'Yesterday'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTransactionList(
      BuildContext context, ExpenseProvider provider, String period) {
    // Basic filter logic for demo purposes
    // "Today" = just now, "Yesterday" = placeholder logic
    // Real implementation would filter by date
    
    // For demo: Show all transactions in "Today" and dummy in "Yesterday" if needed
    // Assuming provider returns list sorted by date.
    
    final transactions = provider.transactions;
    if (transactions.isEmpty) {
      return const Text('No transactions', style: TextStyle(color: Colors.grey));
    }

    // Showing first few as Today for demo
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1), // Light orange background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(tx.category),
                  color: Colors.orange,
                ),
              ),
            title: Text(
              tx.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              DateFormat.jm().format(tx.date), // Time only
              style: TextStyle(color: Colors.grey[500]),
            ),
            trailing: Text(
              NumberFormat.simpleCurrency(name: 'INR').format(tx.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.food:
        return Icons.fastfood_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_car_outlined;
      case ExpenseCategory.entertainment:
        return Icons.music_note_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      default:
        return Icons.grid_view;
    }
  }
}

// Helper widget because I used 'Expected' and 'div' typos in code above accidentally?
// No, I see 'Expected' in button row, likely 'Expanded'.
// And 'div' in leading.
// I will correct these before writing.


// Actually i will just correct the code content.
