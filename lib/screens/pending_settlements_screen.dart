import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/pending_settlement.dart';
import 'package:expense_tracker/providers/pending_settlement_provider.dart';
import 'package:expense_tracker/screens/add_pending_settlement_screen.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class PendingSettlementsScreen extends StatefulWidget {
  const PendingSettlementsScreen({super.key});

  @override
  State<PendingSettlementsScreen> createState() => _PendingSettlementsScreenState();
}

class _PendingSettlementsScreenState extends State<PendingSettlementsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PendingSettlementProvider>(context, listen: false).fetchSettlements());
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
          centerTitle: true,
          title: Text('Pending Settlements', style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18)),
        ),
        floatingActionButton: SafeArea(
          child: ScaleButton(
            child: FloatingActionButton(
              onPressed: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddPendingSettlementScreen(),
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
        body: Consumer<PendingSettlementProvider>(
          builder: (context, provider, child) {
            final settlements = provider.settlements;
            
            double totalPending = 0;
            for (var s in settlements) {
              totalPending += s.remainingAmount;
            }

            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            
            if (settlements.isEmpty) {
              return Center(
                child: Text(
                  'No pending settlements.',
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
                          child: const Icon(Icons.handshake_outlined, color: Colors.black, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: settlements.length,
                    itemBuilder: (context, index) {
                      final settlement = settlements[index];
                      // Wrap item in FadeInSlide with Staggered Delay
                      return FadeInSlide(
                        delay: 0.1 + (index * 0.1),
                        child: _buildSettlementCard(context, settlement, provider)
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

  Widget _buildSettlementCard(BuildContext context, PendingSettlement settlement, PendingSettlementProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: Key(settlement.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (context) {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddPendingSettlementScreen(settlement: settlement),
                  ),
                );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
            ),
            SlidableAction(
              onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Settlement?'),
                      content: const Text('Are you sure you want to delete this settlement?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            provider.deleteSettlement(settlement.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Settlement deleted')),
                            );
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
              },
              backgroundColor: Colors.transparent,
              foregroundColor: const Color(0xFFFE4A49),
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
            ),
          ],
        ),
        child: Container(
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
          child: Theme(
            data: theme.copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              showTrailingIcon: false, 
              title: Row(
                children: [
                  // Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.05) 
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Icon(
                        settlement.type == 'Card' ? Icons.credit_card : Icons.person,
                        color: theme.iconTheme.color,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title & To Whom
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          settlement.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'To: ${settlement.toWhom}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),

                  // Amount & Balance
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                        Text(
                        currencyFormat.format(settlement.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFC6F432) : Colors.black, // Darker text for light mode
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                       if (settlement.remainingAmount > 0)
                           Text(
                            'Bal: ${currencyFormat.format(settlement.remainingAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFF4C4C), // Brighter Red
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                           )
                       else
                           Text(
                            'Settled',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark ? const Color(0xFFC6F432) : const Color(0xFF354012),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                            ),
                           )
                    ],
                  ),
                ],
              ),
              children: [
                   Divider(color: Colors.grey.withOpacity(0.2), height: 32),
                  // History Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Payment History', 
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          )
                        ),
                        
                        // Add Payment Button - Pill Shape
                        GestureDetector(
                            onTap: () => _showAddPaymentDialog(context, settlement, provider),
                            child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                    // Dark olive/green bg for contrast
                                    color: const Color(0xFF354012), 
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFFC6F432).withOpacity(0.3), width: 1)
                                ),
                                child: const Row(
                                    children: [
                                        Icon(Icons.add, size: 16, color: Color(0xFFC6F432)),
                                        SizedBox(width: 6),
                                        Text(
                                          'Add', 
                                          style: TextStyle(
                                            color: Color(0xFFC6F432), 
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14
                                          )
                                        ),
                                    ],
                                ),
                            ),
                        ),
                      ],
                    ),
                  ),
                  
                  if (settlement.paymentHistory.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
                      )
                  else
                      ...settlement.paymentHistory.map((payment) {
                          return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                      Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text(
                                                    DateFormat('dd MMM yyyy').format(payment.date), 
                                                    style: theme.textTheme.bodyMedium?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15
                                                    )
                                                ),
                                                if (payment.note.isNotEmpty)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 4.0),
                                                      child: Text(
                                                          payment.note, 
                                                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 13),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 2,
                                                      ),
                                                    ),
                                            ],
                                        ),
                                      ),
                                      Text(
                                          currencyFormat.format(payment.amount), 
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600, 
                                            color: isDark ? const Color(0xFFC6F432) : Colors.black, // Matching the primary
                                            fontSize: 15
                                          )
                                      ),
                                  ],
                              ),
                          );
                      }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, PendingSettlement settlement, PendingSettlementProvider provider) {
      final amountController = TextEditingController();
      final noteController = TextEditingController();
      DateTime selectedDate = DateTime.now();

      showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);
              return AlertDialog(
                  backgroundColor: theme.cardTheme.color ?? theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Record Payment'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(
                              controller: amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                  labelText: 'Amount Paid',
                                  prefixText: '₹ ',
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: noteController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                  labelText: 'Note (Optional)',
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                                final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                    setState(() {
                                        selectedDate = picked;
                                    });
                                }
                            },
                            child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: theme.scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                    children: [
                                        const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                                        const SizedBox(width: 12),
                                        Text(
                                            DateFormat('dd MMM yyyy').format(selectedDate),
                                            style: theme.textTheme.bodyMedium,
                                        ),
                                    ],
                                ),
                            ),
                          ),
                      ],
                  ),
                  actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                      ),
                      TextButton(
                          onPressed: () {
                              final amount = double.tryParse(amountController.text);
                              if (amount != null && amount > 0) {
                                  provider.addPaymentToSettlement(
                                      settlement.id, 
                                      amount, 
                                      selectedDate,
                                      noteController.text
                                  );
                                  Navigator.of(ctx).pop();
                              }
                          },
                          child: const Text('Save'),
                      ),
                  ],
              );
            } // Builder
          ),
      );
  }
}
