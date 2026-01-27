import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/recurring_payment.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/providers/recurring_payment_provider.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/custom_snackbar.dart';
import 'package:uuid/uuid.dart';

import 'package:expense_tracker/widgets/fade_in_slide.dart';
import 'package:expense_tracker/widgets/scale_button.dart';

class AddRecurringPaymentScreen extends StatefulWidget {
  const AddRecurringPaymentScreen({super.key});

  @override
  State<AddRecurringPaymentScreen> createState() => _AddRecurringPaymentScreenState();
}

class _AddRecurringPaymentScreenState extends State<AddRecurringPaymentScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _tenureController = TextEditingController();

  final _amountFormat = NumberFormat.decimalPattern('en_IN');
  
  DateTime _startDate = DateTime.now();
  DateTime _paymentDate = DateTime.now(); // We'll extract the day from this
  ExpenseCategory _selectedCategory = ExpenseCategory.emi;
  bool _isCurrentMonthCleared = false;

  void _onAmountChanged(String value) {
      if (value.isEmpty) return;
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

  void _presentStartDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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
      if (pickedDate == null) return;
      setState(() {
        _startDate = pickedDate;
      });
    });
  }
  
  void _presentPaymentDatePicker() {
      // Logic to pick a 'day' of the month. 
      // Using standard date picker for simplicity, but we only care about the day.
       showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      lastDate: DateTime(DateTime.now().year, DateTime.now().month + 1, 0), // End of current month
      helpText: 'SELECT PAYMENT DAY',
      builder: (context, child) {
          return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      }
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _paymentDate = pickedDate;
      });
    });
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final enteredTenure = int.tryParse(_tenureController.text);

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      CustomSnackBar.show(context, 'Please enter a valid amount and title.', isError: true);
      return;
    }
    
    if (enteredTenure == null || enteredTenure < 0) {
        CustomSnackBar.show(context, 'Please enter a valid tenure.', isError: true);
        return;
    }

    final capitalizedTitle = enteredTitle.length > 0 
        ? '${enteredTitle[0].toUpperCase()}${enteredTitle.substring(1)}' 
        : enteredTitle;

    final newPayment = RecurringPayment(
      id: const Uuid().v4(),
      title: capitalizedTitle,
      amount: enteredAmount,
      category: _selectedCategory,
      date: _startDate,
      remainingTenure: enteredTenure,
      lastPaymentDate: _isCurrentMonthCleared ? DateTime.now() : null,
      paymentDate: _paymentDate,
    );

    Provider.of<RecurringPaymentProvider>(context, listen: false).addPayment(newPayment);
    
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: ScaleButton(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          ),
          title: Text(
            'Add Recurring Payment', 
            style: Theme.of(context).appBarTheme.titleTextStyle
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               // Amount Input
              FadeInSlide(
                child: Center(
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                      ],
                      onChanged: _onAmountChanged,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 48, 
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color
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
              ),
              const SizedBox(height: 32),
              
              // Title
              FadeInSlide(
                delay: 0.1,
                child: _buildInputField(
                  controller: _titleController,
                  hint: 'Title (e.g. Car Loan)',
                  icon: Icons.edit,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),
              
              // Category
              FadeInSlide(
                delay: 0.15,
                child: Container(
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
                      // Filter mainly for recurring types
                      items: [ExpenseCategory.emi, ExpenseCategory.ccBill, ExpenseCategory.savings, ExpenseCategory.other]
                          .map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Image.asset(category.iconPath, width: 32, height: 32),
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
              ),
              const SizedBox(height: 16),
              
              // Tenure
              FadeInSlide(
                delay: 0.2,
                child: _buildInputField(
                  controller: _tenureController,
                  hint: 'Remaining Tenure (Months)',
                  icon: Icons.timelapse,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 16),

              // Start Date Picker
              FadeInSlide(
                delay: 0.25,
                child: ScaleButton(
                  onTap: _presentStartDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Start Date: ${DateFormat.yMMMd().format(_startDate)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment Date Picker
               FadeInSlide(
                delay: 0.3,
                 child: ScaleButton(
                  onTap: _presentPaymentDatePicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_repeat, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Payment Date: Day ${_paymentDate.day} of every month',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                               ),
               ),
              const SizedBox(height: 24),
              
              // Cleared Toggle
              FadeInSlide(
                delay: 0.35,
                child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                    ),
                    child: SwitchListTile(
                        title: const Text('Current Month Cleared?'),
                        value: _isCurrentMonthCleared,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (val) {
                            setState(() {
                                _isCurrentMonthCleared = val;
                            });
                        },
                    ),
                ),
              ),
              
              const SizedBox(height: 48),

              // Save Button
              FadeInSlide(
                delay: 0.4,
                child: ScaleButton(
                  onTap: _submitData,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFC6F432), Color(0xFFAEE010)],
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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: const Text(
                          'Create Recurring Payment',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Outfit'),
        textCapitalization: textCapitalization,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600]),
          icon: Icon(icon, color: Colors.grey, size: 20),
        ),
      ),
    );
  }
}
