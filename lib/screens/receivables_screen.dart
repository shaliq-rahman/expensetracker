import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/receivable.dart';
import 'package:expense_tracker/providers/receivable_provider.dart';
import 'package:expense_tracker/screens/add_receivable_screen.dart';
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

class ReceivablesScreen extends StatefulWidget {
  const ReceivablesScreen({super.key});

  @override
  State<ReceivablesScreen> createState() => _ReceivablesScreenState();
}

class _ReceivablesScreenState extends State<ReceivablesScreen> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ReceivableProvider>(context, listen: false).fetchReceivables());
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
          title: Text('Receivables', style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 18)),
        ),
        floatingActionButton: SafeArea(
          child: ScaleButton(
            child: FloatingActionButton(
              onPressed: () {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddReceivableScreen(),
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
        body: Consumer<ReceivableProvider>(
          builder: (context, provider, child) {
            final receivables = provider.receivables;
            
            double totalReceivable = 0;
            for (var r in receivables) {
              totalReceivable += r.remainingAmount;
            }

            final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
            
            if (receivables.isEmpty) {
              return Center(
                child: Text(
                  'No receivables.',
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
              );
            }

            return Column(
              children: [
                // Total Receivable Card
                FadeInSlide(
                  duration: const Duration(milliseconds: 600),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
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
                                        'Total Receivable',
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
                                    currencyFormat.format(totalReceivable),
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
                                child: const Icon(Icons.payments_outlined, color: Colors.black, size: 28),
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
                                         receivables
                                             .where((r) => r.type == 'Person' && !r.isSettled)
                                             .fold(0.0, (sum, r) => sum + r.remainingAmount)
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
                                         receivables
                                             .where((r) => r.type == 'Card' && !r.isSettled)
                                             .fold(0.0, (sum, r) => sum + r.remainingAmount)
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
                    itemCount: receivables.length,
                    itemBuilder: (context, index) {
                      final receivable = receivables[index];
                      return FadeInSlide(
                        delay: 0.1 + (index * 0.1),
                        child: _buildReceivableCard(context, receivable, provider)
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

  Widget _buildReceivableCard(BuildContext context, Receivable receivable, ReceivableProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Slidable(
        key: Key(receivable.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (context) {
                 Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddReceivableScreen(receivable: receivable),
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
                      title: const Text('Delete Receivable?'),
                      content: const Text('Are you sure you want to delete this receivable?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            provider.deleteReceivable(receivable.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Receivable deleted')),
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
                        receivable.type == 'Card' ? Icons.credit_card : Icons.person,
                        color: theme.iconTheme.color,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title & From Whom
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receivable.title,
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
                          'From: ${receivable.fromWhom}',
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
                        currencyFormat.format(receivable.amount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFC6F432) : Colors.black,
                          fontSize: 18,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                       if (receivable.remainingAmount > 0)
                           Text(
                            'Bal: ${currencyFormat.format(receivable.remainingAmount)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFFFF4C4C),
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
                  
                  _buildExpandableSection(
                      context, 
                      'Payment History', 
                      () => _showAddPaymentDialog(context, receivable, provider), 
                      _buildPaymentList(context, receivable, provider),
                      isDark ? const Color(0xFFC6F432) : Colors.green.shade700,
                      isDark ? const Color(0xFF354012) : Colors.green.shade50,
                      isDark ? const Color(0xFFC6F432).withOpacity(0.3) : Colors.green.shade300
                  ),
                  
                  // Divider between sections
                  if (receivable.paymentHistory.isNotEmpty || receivable.settlementHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(color: Colors.grey.withOpacity(0.2), height: 1),
                    ),
                  
                  _buildExpandableSection(
                      context, 
                      'Settlement History', 
                      () => _showAddSettlementDialog(context, receivable, provider), 
                      _buildSettlementList(context, receivable, provider),
                      isDark ? Colors.orange.shade400 : Colors.orange.shade700,
                      isDark ? Colors.orange.shade900.withOpacity(0.3) : Colors.orange.shade50,
                      isDark ? Colors.orange.shade700.withOpacity(0.5) : Colors.orange.shade300
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, Receivable receivable, ReceivableProvider provider) {
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
                                  labelText: 'Amount Received',
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
                              
                              if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid amount')),
                                  );
                                  return;
                              }
                              
                              if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a note')),
                                  );
                                  return;
                              }
                              
                              provider.addPaymentToReceivable(
                                  receivable.id, 
                                  amount, 
                                  selectedDate,
                                  noteController.text.trim()
                              );
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

  void _showAddSettlementDialog(BuildContext context, Receivable receivable, ReceivableProvider provider) {
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
                  title: const Text('Record Settlement'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [NumberInputFormatter()],
                              decoration: InputDecoration(
                                  labelText: 'Settlement Amount',
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
                              
                              if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid amount')),
                                  );
                                  return;
                              }
                              
                              if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a note')),
                                  );
                                  return;
                              }
                              
                              provider.addSettlementToReceivable(
                                  receivable.id, 
                                  amount, 
                                  selectedDate,
                                  noteController.text.trim()
                              );
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

  void _showPaymentOptions(BuildContext context, Receivable receivable, ReceivablePayment payment, ReceivableProvider provider) {
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
                _showEditPaymentDialog(context, receivable, payment, provider);
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
                    content: const Text('Are you sure you want to delete this payment entry?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          provider.deletePaymentFromReceivable(receivable.id, payment.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Payment deleted'),
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
                    const Text(
                      'Delete Payment',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSettlementOptions(BuildContext context, Receivable receivable, ReceivableSettlement settlement, ReceivableProvider provider) {
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
                _showEditSettlementDialog(context, receivable, settlement, provider);
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
                      'Edit Settlement',
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
                    title: const Text('Delete Settlement?'),
                    content: const Text('Are you sure you want to delete this settlement entry?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                          provider.deleteSettlementFromReceivable(receivable.id, settlement.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Settlement deleted'),
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
                    const Text(
                      'Delete Settlement',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentDialog(BuildContext context, Receivable receivable, ReceivablePayment payment, ReceivableProvider provider) {
      final formatter = NumberFormat('#,##,###');
      final amountController = TextEditingController(text: formatter.format(payment.amount.toInt()));
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
                                  labelText: 'Amount Received',
                                  prefixText: '₹ ',
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              maxLength: 30,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: noteController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                  labelText: 'Note',
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  counterText: '',
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
                              // Remove commas before parsing
                              final cleanText = amountController.text.replaceAll(',', '');
                              final amount = double.tryParse(cleanText);
                              
                              if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid amount')),
                                  );
                                  return;
                              }
                              
                              if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a note')),
                                  );
                                  return;
                              }
                              
                              print('Editing payment: receivableId=${receivable.id}, paymentId=${payment.id}, amount=$amount, note=${noteController.text.trim()}');
                              provider.editPaymentInReceivable(
                                  receivable.id,
                                  payment.id,
                                  amount, 
                                  selectedDate,
                                  noteController.text.trim()
                              );
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

  void _showEditSettlementDialog(BuildContext context, Receivable receivable, ReceivableSettlement settlement, ReceivableProvider provider) {
      final formatter = NumberFormat('#,##,###');
      final amountController = TextEditingController(text: formatter.format(settlement.amount.toInt()));
      final noteController = TextEditingController(text: settlement.note);
      DateTime selectedDate = settlement.date;

      showDialog(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);
              return AlertDialog(
                  backgroundColor: theme.cardTheme.color ?? theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Edit Settlement'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [NumberInputFormatter()],
                              decoration: InputDecoration(
                                  labelText: 'Settlement Amount',
                                  prefixText: '₹ ',
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                              maxLength: 30,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                              controller: noteController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                  labelText: 'Note',
                                  prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                                  filled: true,
                                  fillColor: theme.scaffoldBackgroundColor,
                                  counterText: '',
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
                              // Remove commas before parsing
                              final cleanText = amountController.text.replaceAll(',', '');
                              final amount = double.tryParse(cleanText);
                              
                              if (amount == null || amount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a valid amount')),
                                  );
                                  return;
                              }
                              
                              if (noteController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please enter a note')),
                                  );
                                  return;
                              }
                              
                              provider.editSettlementInReceivable(
                                  receivable.id,
                                  settlement.id,
                                  amount, 
                                  selectedDate,
                                  noteController.text.trim()
                              );
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


  List<Widget> _buildPaymentList(BuildContext context, Receivable receivable, ReceivableProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    
    // Create virtual payment for initial amount
    // Only add if amount > 0
    final List<ReceivablePayment> allPayments = [];
    if (receivable.amount > 0) {
        allPayments.add(ReceivablePayment(
            id: 'initial', 
            amount: receivable.amount, 
            date: receivable.lentDate, 
            note: receivable.note
        ));
    }
    
    // Combine with history
    allPayments.addAll(receivable.paymentHistory);
    allPayments.sort((a, b) => b.date.compareTo(a.date));
    
    if (allPayments.isEmpty) {
         return [const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
          )];
    }
    
    return allPayments.map((payment) {
          final isInitial = payment.id == 'initial';
          return GestureDetector(
               onLongPress: isInitial ? null : () => _showPaymentOptions(context, receivable, payment, provider),
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
                                     if (isInitial)
                                         Padding(
                                           padding: const EdgeInsets.only(top: 2.0),
                                           child: Text(
                                               'Initial Loan', 
                                               style: TextStyle(color: theme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                           ),
                                         ),
                                 ],
                             ),
                           ),
                           Text(
                               currencyFormat.format(payment.amount), 
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 fontWeight: FontWeight.w600, 
                                 color: isDark ? const Color(0xFFC6F432) : Colors.green.shade700,
                                 fontSize: 15
                               )
                           ),
                       ],
                   ),
               ),
           );
       }).toList();
  }

  List<Widget> _buildSettlementList(BuildContext context, Receivable receivable, ReceivableProvider provider) {
       final theme = Theme.of(context);
       final isDark = theme.brightness == Brightness.dark;
       final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

       if (receivable.settlementHistory.isEmpty) {
           return [const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('No settlements recorded yet.', style: TextStyle(color: Colors.grey)),
              )];
       }

       return (List.from(receivable.settlementHistory)..sort((a, b) => b.date.compareTo(a.date))).map((settlement) {
           return GestureDetector(
               onLongPress: () => _showSettlementOptions(context, receivable, settlement, provider),
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
                                         DateFormat('dd MMM yyyy').format(settlement.date), 
                                         style: theme.textTheme.bodyMedium?.copyWith(
                                           fontWeight: FontWeight.w600,
                                           fontSize: 15
                                         )
                                     ),
                                     if (settlement.note.isNotEmpty)
                                         Padding(
                                           padding: const EdgeInsets.only(top: 4.0),
                                           child: Text(
                                               settlement.note, 
                                               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500], fontSize: 13),
                                               overflow: TextOverflow.ellipsis,
                                               maxLines: 2,
                                           ),
                                         ),
                                 ],
                             ),
                           ),
                           Text(
                               currencyFormat.format(settlement.amount), 
                               style: theme.textTheme.bodyMedium?.copyWith(
                                 fontWeight: FontWeight.w600, 
                                 color: isDark ? Colors.orange.shade400 : Colors.orange.shade700,
                                 fontSize: 15
                               )
                           ),
                       ],
                   ),
               ),
           );
       }).toList();
  }

  Widget _buildExpandableSection(
      BuildContext context, 
      String title, 
      VoidCallback onAdd, 
      List<Widget> children, 
      Color btnColor, 
      Color btnBg, 
      Color btnBorder) {
      
      final theme = Theme.of(context);
      
      return Theme(
          data: theme.copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding: EdgeInsets.symmetric(horizontal: 0),
              childrenPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading, // Moves chevron to left
              title: Text(
                  title, 
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  )
              ),
              trailing: GestureDetector(
                    onTap: onAdd,
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: btnBg, 
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: btnBorder, 
                              width: 1
                            )
                        ),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                Icon(
                                  Icons.add, 
                                  size: 16, 
                                  color: btnColor
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Add', 
                                  style: TextStyle(
                                    color: btnColor, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14
                                  )
                                ),
                            ],
                        ),
                    ),
              ),
              children: [
                   Container(
                       constraints: const BoxConstraints(maxHeight: 300),
                       child: ListView(
                           padding: EdgeInsets.zero,
                           shrinkWrap: true,
                           primary: false,
                           children: children,
                       ),
                   )
              ],
          ),
      );
  }
}

