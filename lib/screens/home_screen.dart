import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/providers/theme_provider.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onAddExpense;
  final VoidCallback onViewAll;

  const HomeScreen({super.key, required this.onAddExpense, required this.onViewAll});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _filterType = 'Month'; // Default to Month // 'Day', 'Month', 'Year'
  DateTime _selectedDate = DateTime.now();

  void _updateFilter(String type) {
    setState(() {
      _filterType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    
    // Get filtered data
    final income = expenseProvider.getPeriodIncome(_filterType, _selectedDate);
    final expense = expenseProvider.getPeriodExpense(_filterType, _selectedDate);
    
    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show gradient from parent
      appBar: AppBar(
        title: Row(
          children: [
            Text('Home', style: Theme.of(context).appBarTheme.titleTextStyle),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Provider.of<ThemeProvider>(context).isDarkMode ? Icons.wb_sunny : Icons.nightlight_round,
                  color: Theme.of(context).iconTheme.color,
                  size: 20,
                ),
                onPressed: () {
                  final provider = Provider.of<ThemeProvider>(context, listen: false);
                  provider.toggleTheme(!provider.isDarkMode);
                },
                constraints: const BoxConstraints(), // Minimizes padding constraints
                padding: const EdgeInsets.all(8), // Add padding manually for touch target
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent, // Gradient visibility
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
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none, color: Theme.of(context).iconTheme.color),
              onPressed: () {},
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // Split Balance Card (Income vs Expense)
              _buildSplitBalanceCard(income, expense),
              
              const SizedBox(height: 20),

              // Total Balance Card
              _buildBalanceCard(income - expense),
              
              const SizedBox(height: 32),
              
              // Recent Transfers Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transfers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                  ),
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: Text(
                      'View All', 
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
              
              // Transaction List
              _buildTransactionList(context, expenseProvider),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // Use surface for contrast
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.account_balance_wallet, color: Theme.of(context).iconTheme.color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                'Total Balance',
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(balance),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSplitBalanceCard(double income, double expense) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('Income', income, const Color(0xFF00C853), Icons.arrow_downward),
        ),
        const SizedBox(width: 16),
        // For Expense Amount Color: Use Dynamic Text Color instead of fixed white
        Expanded(
          child: _buildStatCard('Expense', expense, Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black, Icons.arrow_upward),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, Color amountColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.all(8), // Increased padding
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor, // Use scaffold bg for contrast within card
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Theme.of(context).iconTheme.color, size: 18), // Icon color dynamic
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context, ExpenseProvider provider) {
    final transactions = provider.getFilteredTransactions(_filterType, _selectedDate);
    
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text('No transactions for this period', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final reversedList = List<Transaction>.from(transactions.reversed);

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: reversedList.length,
      itemBuilder: (context, index) {
        final tx = reversedList[index];
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
                  color: Colors.transparent, // Semi-transparent bg to let icon shine
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
                        fontFamily: 'Outfit', // Ensure font is used if available or default
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
                   // Color Coded Amount: Green for Income, Red for Expense
                  Text(
                    '${isIncome ? '+' : '-'} ${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(tx.amount)}',
                    style: TextStyle(
                      color: isIncome ? const Color(0xFF00C853) : Theme.of(context).textTheme.bodyLarge?.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                   // Optional subtext in design (e.g. converted currency), skipping for now or placeholder
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
