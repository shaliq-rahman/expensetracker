import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  PaymentMode _selectedPaymentMode = PaymentMode.cash;
  TransactionType _transactionType = TransactionType.expense; // Default to expense for this design

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _submitData() {
    final enteredTitle = _titleController.text; // "Food", "Travel" etc
    final enteredAmount = double.tryParse(_amountController.text);
    final enteredNote = _noteController.text;

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      // Show error snackbar?
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and title.')),
      );
      return;
    }

    Provider.of<ExpenseProvider>(context, listen: false).addTransaction(
      Transaction(
        title: enteredTitle, // User creates title like "Dinner" but usually selects category. 
                             // In this design, title seems to be "Food" (category name) or custom.
                             // We'll use the title input for now.
        amount: enteredAmount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _transactionType,
        paymentMode: _selectedPaymentMode,
        note: enteredNote.isNotEmpty ? enteredNote : null,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Expense', style: TextStyle(color: Colors.black)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Toggle
            Center(
              child: SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text("Expense"),
                    icon: Icon(Icons.money_off),
                  ),
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text("Income"),
                    icon: Icon(Icons.attach_money),
                  ),
                ],
                selected: {_transactionType},
                onSelectionChanged: (Set<TransactionType> newSelection) {
                  setState(() {
                    _transactionType = newSelection.first;
                    // Reset category if it doesn't match new type
                    if (_transactionType == TransactionType.income) {
                        if (!_selectedCategory.isIncome && _selectedCategory != ExpenseCategory.other) {
                            _selectedCategory = ExpenseCategory.salary;
                        }
                    } else {
                        if (_selectedCategory.isIncome) {
                            _selectedCategory = ExpenseCategory.food;
                        }
                    }
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFFDD835);
                    }
                    return Colors.grey.shade100;
                  }),
                  foregroundColor: WidgetStateProperty.all(Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Amount Input
            Center(
              child: IntrinsicWidth(
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold,
                      color: _transactionType == TransactionType.income ? Colors.green : Colors.black
                  ),
                  decoration: InputDecoration(
                    prefixText: 'INR ', 
                    prefixStyle: TextStyle(fontSize: 24, color: Colors.grey[400], fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[300]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Title / Category
            _buildInputField(
              controller: _titleController,
              hint: 'Title (e.g. Dinner)',
              icon: Icons.edit,
            ),
            
            const SizedBox(height: 16),
            
            // Category Dropdown (Custom styled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExpenseCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: const Icon(Icons.chevron_right),
                  items: ExpenseCategory.values
                      .where((cat) => _transactionType == TransactionType.income 
                          ? (cat.isIncome || cat == ExpenseCategory.other) 
                          : (!cat.isIncome || cat == ExpenseCategory.other))
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(_getCategoryIcon(category), size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 12),
                          Text(category.name.toUpperCase(), style: TextStyle(color: Colors.grey[800])),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),
            
            // Note
            _buildInputField(
              controller: _noteController,
              hint: 'Note (Optional)',
              icon: Icons.notes,
            ),

            const SizedBox(height: 16),

            // Date Picker Row
            GestureDetector(
              onTap: _presentDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat.yMMMd().format(_selectedDate),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Payment Mode (Chips)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: PaymentMode.values.map((mode) {
                final isSelected = _selectedPaymentMode == mode;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedPaymentMode = mode;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFF9C4) : const Color(0xFFF6F6F6), // Light yellow vs Light grey
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: const Color(0xFFFDD835), width: 2) : null,
                        ),
                        child: Icon(
                          _getPaymentIcon(mode),
                          color: isSelected ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        mode.toString().split('.').last.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDD835),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          icon: Icon(icon, color: Colors.grey, size: 20),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
     switch (category) {
      case ExpenseCategory.food:
        return Icons.fastfood_outlined;
      case ExpenseCategory.transport:
        return Icons.directions_bus_outlined;
      case ExpenseCategory.entertainment:
        return Icons.movie_outlined;
      case ExpenseCategory.bills:
        return Icons.receipt_long_outlined;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag_outlined;
      case ExpenseCategory.health:
        return Icons.local_hospital_outlined;
      case ExpenseCategory.education:
        return Icons.school_outlined;
      case ExpenseCategory.salary:
        return Icons.attach_money;
      case ExpenseCategory.investment:
        return Icons.trending_up;
      case ExpenseCategory.other:
        return Icons.category_outlined;
    }
  }

  IconData _getPaymentIcon(PaymentMode mode) {
    switch (mode) {
      case PaymentMode.cash:
        return Icons.account_balance_wallet_outlined;
      case PaymentMode.upi:
        return Icons.qr_code;
      case PaymentMode.card:
        return Icons.credit_card;
    }
  }
}
