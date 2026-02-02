import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/providers/theme_provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:expense_tracker/screens/add_transaction_screen.dart';
import 'package:expense_tracker/screens/edit_profile_screen.dart';
import 'package:expense_tracker/widgets/custom_snackbar.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              String displayName = 'User';
              String? photoUrl;
              
              if (snapshot.hasData && snapshot.data?.data() != null) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                displayName = data['displayName'] ?? 'User';
                photoUrl = data['photoUrl'];
              }
              
              return Row(
                children: [
                  ScaleButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFFC6F432)
                          : Theme.of(context).cardTheme.color,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null 
                        ? Icon(
                            Icons.person,
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.black 
                                : Theme.of(context).iconTheme.color,
                            size: 24,
                          )
                        : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          ScaleButton(
            onTap: () {
              final provider = Provider.of<ThemeProvider>(context, listen: false);
              provider.toggleTheme(!provider.isDarkMode);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Provider.of<ThemeProvider>(context).isDarkMode 
                  ? Icons.wb_sunny 
                  : Icons.nightlight_round,
                color: Theme.of(context).iconTheme.color,
                size: 20,
              ),
            ),
          ),
          ScaleButton(
            onTap: () {
              // Search functionality
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.search,
                color: Theme.of(context).iconTheme.color,
                size: 22,
              ),
            ),
          ),
          ScaleButton(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                Icons.notifications_none,
                color: Theme.of(context).iconTheme.color,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Welcome Message
              FadeInSlide(
                duration: const Duration(milliseconds: 600),
                child: _buildWelcomeSection(),
              ),
              
              const SizedBox(height: 32),

              // Card-Style Balance Display
              FadeInSlide(
                delay: 0.1,
                duration: const Duration(milliseconds: 600),
                child: _buildCardStyleBalance(income, expense, income - expense),
              ),
              
              const SizedBox(height: 32),
              
              // Recent Activity Header
              FadeInSlide(
                delay: 0.2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.titleLarge?.color),
                    ),
                    ScaleButton(
                      onTap: widget.onViewAll,
                      child: Row(
                        children: [
                          Text(
                            'See all', 
                            style: TextStyle(color: Colors.grey[500], fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios, color: Colors.grey[500], size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
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

  Widget _buildWelcomeSection() {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back 👋',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Smart Solutions\nfor Smart Money.',
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCardStyleBalance(double income, double expense, double balance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF2A2D2E),
                const Color(0xFF1F2122),
              ]
            : [
                const Color(0xFF3A3D3E),
                const Color(0xFF2F3132),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period filter and card type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BALANCE',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              // Period filter
              ScaleButton(
                child: PopupMenuButton<String>(
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _filterType,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Card Balance Label
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          
          // Balance Amount
          Row(
            children: [
              Text(
                NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(balance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFC6F432).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFFC6F432),
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Income and Expense Stats
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Color(0xFF00C853),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Income',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(income),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Color(0xFFFF6B6B),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expense',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(expense),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.titleLarge?.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add\nTransaction',
                onTap: widget.onAddExpense,
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                icon: Icons.analytics_outlined,
                label: 'View\nAnalytics',
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                icon: Icons.repeat,
                label: 'Recurring\nPayments',
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _buildQuickActionButton(
                icon: Icons.people_outline,
                label: 'Pending\nSettlements',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark 
              ? Colors.white.withOpacity(0.08) 
              : Colors.black.withOpacity(0.05),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC6F432).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC6F432),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
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

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final isIncome = tx.type == TransactionType.income;
        
        return FadeInSlide(
          delay: 0.3 + (index * 0.1), // Staggered delay starting after cards
          child: Padding(
            key: ValueKey(tx.id),
            padding: const EdgeInsets.only(bottom: 16),
            child: Slidable(
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                extentRatio: 0.5, // Adjust width of actions to be reasonable
                children: [
                  SlidableAction(
                    onPressed: (context) {
                       Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddTransactionScreen(transaction: tx),
                        ),
                      );
                    },
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                  SlidableAction(
                    onPressed: (context) {
                       provider.deleteTransaction(tx.id);
                       CustomSnackBar.show(context, 'Transaction deleted');
                    },
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFFFE4A49),
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              child: Container(
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
                        color: Colors.transparent,
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
              ),
            ),
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
