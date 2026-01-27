import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/recurring_payment.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/providers/recurring_payment_provider.dart';
import 'package:expense_tracker/screens/add_recurring_payment_screen.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';

import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';

class RecurringPaymentsScreen extends StatefulWidget {
  const RecurringPaymentsScreen({super.key});

  @override
  State<RecurringPaymentsScreen> createState() => _RecurringPaymentsScreenState();
}

class _RecurringPaymentsScreenState extends State<RecurringPaymentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<RecurringPaymentProvider>(context, listen: false).fetchPayments());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: ScaleButton(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          ),
          title: Text('Recurring Payments', style: theme.appBarTheme.titleTextStyle),
        ),
        floatingActionButton: SafeArea(
          child: ScaleButton(
            child: FloatingActionButton(
              onPressed: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddRecurringPaymentScreen(),
                  ),
                );
              },
              backgroundColor: Theme.of(context).brightness == Brightness.dark 
                  ? theme.colorScheme.primary 
                  : Colors.black,
              child: Icon(
                Icons.add, 
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black 
                    : theme.colorScheme.primary
              ),
            ),
          ),
        ),
        body: Consumer<RecurringPaymentProvider>(
          builder: (context, provider, child) {
            final payments = provider.payments;
            
            double totalPending = 0;
            for (var payment in payments) {
              totalPending += payment.amount * payment.remainingTenure;
            }

            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            
            if (payments.isEmpty) {
              return Center(
                child: Text(
                  'No recurring payments added yet.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              );
            }

            return Column(
              children: [
                // Total Pending Card
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.8),
                          theme.colorScheme.primary
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Pending',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              currencyFormat.format(totalPending),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.account_balance_wallet, color: Colors.black, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      // Wrap item in FadeInSlide with Staggered Delay
                      return FadeInSlide(
                        delay: 0.1 + (index * 0.1),
                        child: _buildPaymentCard(context, payment, provider)
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(BuildContext context, RecurringPayment payment, RecurringPaymentProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Dismissible(
      key: Key(payment.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to remove this recurring payment?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deletePayment(payment.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
               Container(
                  width: 70, 
                  height: 70,
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.transparent, 
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    payment.category.iconPath,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.category, color: isDark ? Colors.white : Colors.black, size: 24);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Next: ${DateFormat('d MMM').format(DateTime(
                            DateTime.now().year, 
                            DateTime.now().month, 
                            payment.paymentDate.day
                        ))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currencyFormat.format(payment.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? theme.colorScheme.primary : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.remainingTenure} months left', // Simple logic, might need refinement based on start date
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                        fontSize: 10
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Current Month Cleared',
                  style: theme.textTheme.bodyMedium,
                ),
                Switch(
                  value: payment.isCurrentMonthCleared,
                  activeColor: isDark ? theme.colorScheme.primary : Colors.black,
                  activeTrackColor: isDark ? theme.colorScheme.primary.withOpacity(0.5) : Colors.black.withOpacity(0.1),
                  inactiveThumbColor: Colors.grey,
                  inactiveTrackColor: Colors.grey.withOpacity(0.3),
                  onChanged: (val) {
                    provider.toggleCurrentMonthCleared(payment.id, val);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
