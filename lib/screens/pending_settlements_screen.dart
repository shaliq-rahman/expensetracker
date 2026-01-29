import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/pending_settlement.dart';
import 'package:expense_tracker/providers/pending_settlement_provider.dart';
import 'package:expense_tracker/screens/add_pending_settlement_screen.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Custom formatter for number input with comma formatting
class NumberInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,##,###');
  
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    // Parse and format with commas
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final formatted = _formatter.format(number);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PendingSettlementsScreen extends StatefulWidget {
  const PendingSettlementsScreen({super.key});

  @override
  State<PendingSettlementsScreen> createState() => _PendingSettlementsScreenState();
}

class _PendingSettlementsScreenState extends State<PendingSettlementsScreen> {
  bool _isExpanded = false;

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
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                         // Toggle expansion state locally or in provider?
                         // Since I don't have local state for this yet in the snippet provided (it's stateless or state is managed elsewhere?), 
                         // Wait, the class is _PendingSettlementsScreenState (Stateful).
                         // I need to define bool _isExpanded = false; in the class.
                         // But I can't inject variable definition easily with replace_file_content unless I replace the whole class start.
                         // I will assume I can add it, OR I'll make the header tappable and use a local variable if I could.
                         // Actually, I must add the state variable.
                         // I'll do this in two steps or use a workaround? 
                         // No, I should add the variable. 
                         // Check line 27 in previous view (Step 351/491 was RecurringPayments/PendingSettlements).
                         // pending_settlements_screen.dart is Stateful.
                         _isExpanded = !_isExpanded;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Total Pending',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: Colors.black54,
                                        size: 16,
                                      ),
                                    ],
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
                          if (_isExpanded) ...[
                             const SizedBox(height: 20),
                             Divider(color: Colors.black.withOpacity(0.1)),
                             const SizedBox(height: 10),
                             
                             // Person and Card Totals in Same Row
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 // Person Total
                                 Row(
                                   children: [
                                     const Icon(Icons.person, size: 20, color: Colors.black54),
                                     const SizedBox(width: 8),
                                     Text(
                                       currencyFormat.format(
                                         settlements
                                             .where((s) => s.type == 'Person' && !s.isSettled)
                                             .fold(0.0, (sum, s) => sum + s.remainingAmount)
                                       ),
                                       style: const TextStyle(
                                         color: Colors.black,
                                         fontSize: 16,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(width: 24),
                                 // Card Total
                                 Row(
                                   children: [
                                     const Icon(Icons.credit_card, size: 20, color: Colors.black54),
                                     const SizedBox(width: 8),
                                     Text(
                                       currencyFormat.format(
                                         settlements
                                             .where((s) => s.type == 'Card' && !s.isSettled)
                                             .fold(0.0, (sum, s) => sum + s.remainingAmount)
                                       ),
                                       style: const TextStyle(
                                         color: Colors.black,
                                         fontSize: 16,
                                         fontWeight: FontWeight.bold,
                                       ),
                                     ),
                                   ],
                                 ),
                               ],
                             ),
                          ],
                        ],
                      ),
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
                      Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              primary: false,
                              children: (List.from(settlement.paymentHistory)..sort((a, b) => b.date.compareTo(a.date))).map((payment) {
                                  return GestureDetector(
                                      onLongPress: () => _showPaymentOptions(context, settlement, payment, provider),
                                      child: Padding(
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
                                                        color: isDark ? const Color(0xFFC6F432) : Colors.black,
                                                        fontSize: 15
                                                      )
                                                  ),
                                              ],
                                          ),
                                      ),
                                  );
                              }).toList(),
                          ),
                      ),
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
                              keyboardType: TextInputType.number,
                              inputFormatters: [NumberInputFormatter()],
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
                              maxLength: 30,
                              decoration: InputDecoration(
                                  labelText: 'Note',
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  counterText: '',
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
                              // Remove commas before parsing
                              final cleanText = amountController.text.replaceAll(',', '');
                              final amount = double.tryParse(cleanText);
                              if (amount != null && amount > 0 && noteController.text.trim().isNotEmpty) {
                                  provider.addPaymentToSettlement(
                                      settlement.id, 
                                      amount, 
                                      selectedDate,
                                      noteController.text.trim()
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

  void _showPaymentOptions(BuildContext context, PendingSettlement settlement, SettlementPayment payment, PendingSettlementProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color ?? theme.cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Edit option
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _showEditPaymentDialog(context, settlement, payment, provider);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: isDark 
                    ? Colors.white.withOpacity(0.05) 
                    : Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark 
                      ? Colors.white.withOpacity(0.1) 
                      : Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark 
                          ? Colors.white.withOpacity(0.1) 
                          : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined, 
                        color: theme.iconTheme.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Edit Payment',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Delete option
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: theme.cardTheme.color ?? theme.cardColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Delete Payment?'),
                    content: const Text('Are you sure you want to delete this payment record?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          provider.deletePaymentFromSettlement(settlement.id, payment);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Payment deleted successfully'),
                              backgroundColor: theme.cardTheme.color ?? theme.cardColor,
                            ),
                          );
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_outline, 
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Delete Payment',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, PendingSettlement settlement, SettlementPayment payment, PendingSettlementProvider provider) {
      final amountController = TextEditingController(text: NumberFormat("#,##,###").format(payment.amount));
      final noteController = TextEditingController(text: payment.note);
      DateTime selectedDate = payment.date;

      showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);
              return AlertDialog(
                  backgroundColor: theme.cardTheme.color ?? theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Edit Payment'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [NumberInputFormatter()],
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
                              maxLength: 30,
                              decoration: InputDecoration(
                                  labelText: 'Note',
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  counterText: '',
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
                              final cleanText = amountController.text.replaceAll(',', '');
                              final amount = double.tryParse(cleanText);
                              
                              if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
                                  return;
                              }
                              if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a note')));
                                  return;
                              }

                              final updatedPayment = SettlementPayment(
                                  id: payment.id,
                                  amount: amount,
                                  date: selectedDate,
                                  note: noteController.text.trim()
                              );
                              provider.editPaymentInSettlement(settlement.id, payment, updatedPayment);
                              Navigator.of(ctx).pop();
                          },
                          child: const Text('Save'),
                      ),
                  ],
              );
            }
          ),
      );
  }

  Widget _buildBreakdownSection(String title, List<PendingSettlement> settlements, String Function(PendingSettlement) grouper, NumberFormat currencyFormat) {
    final Map<String, double> totals = {};
    for (var s in settlements) {
      if (!s.isSettled) {
        totals.update(grouper(s), (val) => val + s.remainingAmount, ifAbsent: () => s.remainingAmount);
      }
    }

    if (totals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...totals.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.key.isEmpty ? 'Unknown' : entry.key,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  currencyFormat.format(entry.value),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}
