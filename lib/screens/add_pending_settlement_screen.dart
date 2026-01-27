import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/pending_settlement.dart';
import 'package:expense_tracker/providers/pending_settlement_provider.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';

class AddPendingSettlementScreen extends StatefulWidget {
  final PendingSettlement? settlement;
  const AddPendingSettlementScreen({super.key, this.settlement});

  @override
  State<AddPendingSettlementScreen> createState() => _AddPendingSettlementScreenState();
}

class _AddPendingSettlementScreenState extends State<AddPendingSettlementScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  final _toWhomController = TextEditingController();
  final _amountFormat = NumberFormat.decimalPattern('en_IN');
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.settlement != null) {
        _titleController.text = widget.settlement!.title;
        _amountController.text = _amountFormat.format(widget.settlement!.amount);
        _toWhomController.text = widget.settlement!.toWhom;
        _selectedDate = widget.settlement!.expectedClosingDate;
        // Logic for paid amount in edit mode:
        // Usually we don't edit "Paid Amount" directly in edit mode if it's a history, 
        // but for simplicity, we might leave it empty or show separate logic. 
        // User didn't specify. Assuming "Edit" updates core details (Title, ToWhom, Total Amount).
        // If we change Total Amount, logic for Remaining needs to hold. 
        // If this is a new "Paid Amount" entry, user should use the Add Payment flow.
        // So I will disable or hide "Paid Amount" field in Edit Mode to avoid confusion, 
        // or just let it act as "Adding Initial Payment" (which is weird in Edit).
        // Better: Hide Paid Amount in Edit Mode.
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

  // _onPaidAmountChanged remains same...
  void _onPaidAmountChanged(String value) {
      if (value.isEmpty) return;
      String rawValue = value.replaceAll(',', '');
      if (rawValue.isEmpty) return;
      double? number = double.tryParse(rawValue);
      if (number == null) return;
      String formatted = _amountFormat.format(number);
      if (value != formatted) {
          _paidAmountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
          );
      }
  }


  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020), // Allow past dates for editing
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveSettlement() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final enteredPaidAmount = double.tryParse(_paidAmountController.text.replaceAll(',', '')) ?? 0.0;
    final enteredToWhom = _toWhomController.text;

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and title.')),
      );
      return;
    }

    if (enteredToWhom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter who this settlement is for.')),
        );
        return;
    }

    final provider = Provider.of<PendingSettlementProvider>(context, listen: false);

    if (widget.settlement != null) {
        // Update Logic
        final updatedSettlement = PendingSettlement(
            id: widget.settlement!.id,
            title: enteredTitle,
            amount: enteredAmount,
            paymentHistory: widget.settlement!.paymentHistory, // Keep existing history
            toWhom: enteredToWhom,
            expectedClosingDate: _selectedDate,
            isSettled: widget.settlement!.isSettled,
        );
        provider.updateSettlement(updatedSettlement);
    } else {
        // Create Logic
        final settlement = PendingSettlement(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: enteredTitle,
          amount: enteredAmount,
          paymentHistory: enteredPaidAmount > 0 
              ? [SettlementPayment(amount: enteredPaidAmount, date: DateTime.now())]
              : [],
          toWhom: enteredToWhom,
          expectedClosingDate: _selectedDate,
        );
        provider.addSettlement(settlement);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.settlement != null;
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
          title: Text(isEditing ? 'Edit Settlement' : 'Add Pending Settlement', style: Theme.of(context).appBarTheme.titleTextStyle),
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
                  hint: 'Title (e.g. Dinner)',
                  icon: Icons.edit,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),
              
              // To Whom
              FadeInSlide(
                delay: 0.15,
                child: _buildInputField(
                  controller: _toWhomController,
                  hint: 'To Whom (e.g. John)',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: 16),
              
              // Paid Amount - Hide in Edit Mode
              if (!isEditing)
                  FadeInSlide(
                    delay: 0.2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _paidAmountController,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         onChanged: _onPaidAmountChanged,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Paid Amount (Optional)',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          icon: const Icon(Icons.money_off, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                  ),
              if (!isEditing) const SizedBox(height: 16),
 
              // Date Picker
              FadeInSlide(
                delay: 0.25,
                child: ScaleButton(
                  onTap: () => _selectDate(context),
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
                            'Expected Closing: ${DateFormat('d MMM yyyy').format(_selectedDate)}',
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
              
              const SizedBox(height: 48),

              // Save Button
              FadeInSlide(
                delay: 0.3,
                child: ScaleButton(
                  onTap: _saveSettlement,
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
                        child: Text(
                          isEditing ? 'Update Settlement' : 'Save Settlement',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
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
