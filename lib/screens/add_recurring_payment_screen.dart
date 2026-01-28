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
  final RecurringPayment? payment;

  const AddRecurringPaymentScreen({super.key, this.payment});

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

  @override
  void initState() {
    super.initState();
    if (widget.payment != null) {
      final payment = widget.payment!;
      _titleController.text = payment.title;
      _amountController.text = _amountFormat.format(payment.amount);
      _tenureController.text = payment.remainingTenure.toString();
      _startDate = payment.date;
      _paymentDate = payment.paymentDate;
      _selectedCategory = payment.category;
      _isCurrentMonthCleared = payment.isCurrentMonthCleared;
    }
  }

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
      initialDate: _startDate,
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
      initialDate: _paymentDate,
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
      id: widget.payment?.id ?? const Uuid().v4(),
      title: capitalizedTitle,
      amount: enteredAmount,
      category: _selectedCategory,
      date: _startDate,
      remainingTenure: enteredTenure,
      lastPaymentDate: _isCurrentMonthCleared ? DateTime.now() : widget.payment?.lastPaymentDate, // Keep old lastPaymentDate if not toggled, or update if toggled
      paymentDate: _paymentDate,
    );

    if (widget.payment != null) {
      Provider.of<RecurringPaymentProvider>(context, listen: false).updatePayment(newPayment);
    } else {
      Provider.of<RecurringPaymentProvider>(context, listen: false).addPayment(newPayment);
    }
    
    Navigator.of(context).pop();
  }

  void _showCategorySelector() {
    final categories = [ExpenseCategory.emi, ExpenseCategory.ccBill, ExpenseCategory.savings, ExpenseCategory.other]
      ..sort((a, b) => a.name.compareTo(b.name)); // Sort alphabetically

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Category',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    ScaleButton(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).iconTheme.color,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Category Grid
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.0, 
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return ScaleButton(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFC6F432).withOpacity(0.2)
                              : Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected 
                                ? const Color(0xFFC6F432)
                                : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFC6F432).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              category.iconPath,
                              width: 48,
                              height: 48,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.category, size: 48),
                            ),
                            const SizedBox(height: 8), 
                            Text(
                              category.name.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11, 
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFFC6F432)
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                fontFamily: 'Outfit',
                              ),
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
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
          centerTitle: true,
          title: Text(
            'Add Recurring Payment', 
            style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 18)
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
              
              // Category Selection (Custom Dialog)
              FadeInSlide(
                delay: 0.15,
                child: ScaleButton(
                  onTap: () => _showCategorySelector(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Image.asset(
                          _selectedCategory.iconPath,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.category, size: 40),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedCategory.name.toUpperCase(),
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                              fontFamily: 'Outfit',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                      ],
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
