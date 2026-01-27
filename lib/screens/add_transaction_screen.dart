import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/providers/expense_provider.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';

import 'package:expense_tracker/widgets/custom_snackbar.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  final _amountFormat = NumberFormat.decimalPattern('en_IN');

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _titleController.text = tx.title;
      _amountController.text = _amountFormat.format(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.date;
      _selectedTime = TimeOfDay.fromDateTime(tx.date);
      _selectedCategory = tx.category;
      _transactionType = tx.type;
      _selectedPaymentMode = tx.paymentMode;
    }
  }

  void _onAmountChanged(String value) {
      if (value.isEmpty) return;
      
      // Remove commands to get raw number
      String rawValue = value.replaceAll(',', '');
      
      if (rawValue.isEmpty) return;
      
      double? number = double.tryParse(rawValue);
      
      if (number == null) return;
      
      String formatted = _amountFormat.format(number);
      
      if (value != formatted) {
          _amountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
          );
      }
  }
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  ExpenseCategory _selectedCategory = ExpenseCategory.shopping;
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

  void _presentTimePicker() {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
         return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: const Color(0xFF161618),
              hourMinuteTextColor: Colors.white,
              dayPeriodTextColor: Colors.white,
              dialHandColor: Theme.of(context).primaryColor,
              dialBackgroundColor: Colors.grey[800],
              entryModeIconColor: Colors.white,
              hourMinuteColor: MaterialStateColor.resolveWith((states) => 
                  states.contains(MaterialState.selected) ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.grey[800]!),
            ),
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.black,
              surface: const Color(0xFF161618),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedTime) {
      if (pickedTime == null) {
        return;
      }
      setState(() {
        _selectedTime = pickedTime;
      });
    });
  }

  void _submitData() {
    final enteredTitle = _titleController.text; // "Food", "Travel" etc
    final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final enteredNote = _noteController.text;

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      // Show error snackbar?
      CustomSnackBar.show(context, 'Please enter a valid amount and title.', isError: true);
      return;
    }

    // Capitalize Title
    final capitalizedTitle = enteredTitle.length > 0 
        ? '${enteredTitle[0].toUpperCase()}${enteredTitle.substring(1)}' 
        : enteredTitle;

    final combinedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Provider.of<ExpenseProvider>(context, listen: false).addTransaction(
      Transaction(
        id: widget.transaction?.id, // Preserve ID if editing
        title: capitalizedTitle,
        amount: enteredAmount,
        date: combinedDateTime,
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to show gradient
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.transaction == null ? 'Add Expense' : 'Edit Expense', 
          style: Theme.of(context).appBarTheme.titleTextStyle
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: Theme.of(context).iconTheme.color),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type Toggle (Custom Curved Card)
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                     _buildToggleOption(TransactionType.expense, Icons.money_off),
                     _buildToggleOption(TransactionType.income, Icons.attach_money),
                  ],
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')), // Allow digits and commas
                  ],
                  onChanged: _onAmountChanged,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 48, 
                      fontWeight: FontWeight.bold,
                      color: _transactionType == TransactionType.income ? const Color(0xFFC6F432) : Theme.of(context).textTheme.bodyLarge?.color
                  ),
                  decoration: InputDecoration(
                    prefixText: '₹ ', 
                    prefixStyle: TextStyle(fontSize: 24, color: Colors.grey[600], fontWeight: FontWeight.bold),
                    border: InputBorder.none,
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey[800]),
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
              textCapitalization: TextCapitalization.sentences,
            ),
            
            const SizedBox(height: 16),
            
            // Category Dropdown (Custom styled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExpenseCategory>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardTheme.color,
                  icon: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                  items: ExpenseCategory.values
                      .where((cat) => _transactionType == TransactionType.income 
                          ? (cat.isIncome || cat == ExpenseCategory.other) 
                          : (!cat.isIncome || cat == ExpenseCategory.other))
                      .map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Image.asset(category.iconPath, width: 40, height: 40),
                          const SizedBox(width: 12),
                          Text(
                            category.name.toUpperCase(), 
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                          ),
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

            // Date & Time Pickers
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _presentDatePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            DateFormat.yMMMd().format(_selectedDate),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: _presentTimePicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: Colors.grey, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _selectedTime.format(context),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                          color: isSelected ? const Color(0xFFC6F432) : Theme.of(context).cardTheme.color, // Lime Green vs Dark Grey
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                          // border: isSelected ? Border.all(color: const Color(0xFFC6F432), width: 2) : null,
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
                          color: isSelected ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            
            // Save Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFC6F432), Color(0xFFAEE010)], // Lime Green Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC6F432).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Transparent for gradient
                  shadowColor: Colors.transparent, // Remove button shadow
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.transaction == null ? 'Save Expense' : 'Update Expense',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildToggleOption(TransactionType type, IconData icon) {
    final isSelected = _transactionType == type;
    return GestureDetector(
      onTap: () {
          setState(() {
            _transactionType = type;
            // Reset category if it doesn't match new type
            if (_transactionType == TransactionType.income) {
                if (!_selectedCategory.isIncome && _selectedCategory != ExpenseCategory.other) {
                    _selectedCategory = ExpenseCategory.freelance;
                }
            } else {
                if (_selectedCategory.isIncome) {
                    _selectedCategory = ExpenseCategory.shopping;
                }
            }
          });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFC6F432) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.black : Colors.grey),
            const SizedBox(width: 8),
            Text(
              type.name.replaceFirst(type.name[0], type.name[0].toUpperCase()),
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: FontWeight.bold,
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
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          icon: Icon(icon, color: Colors.grey, size: 20),
        ),
      ),
    );
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
