import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/models/receivable.dart';
import 'package:expense_tracker/providers/receivable_provider.dart';
import 'package:expense_tracker/widgets/scale_button.dart';
import 'package:expense_tracker/widgets/gradient_background.dart';
import 'package:expense_tracker/widgets/fade_in_slide.dart';

class AddReceivableScreen extends StatefulWidget {
  final Receivable? receivable;
  const AddReceivableScreen({super.key, this.receivable});

  @override
  State<AddReceivableScreen> createState() => _AddReceivableScreenState();
}

class _AddReceivableScreenState extends State<AddReceivableScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _receivedAmountController = TextEditingController();
  final _fromWhomController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFormat = NumberFormat.decimalPattern('en_IN');
  DateTime _lentDate = DateTime.now();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String _selectedType = 'Person';

  @override
  void initState() {
    super.initState();
    if (widget.receivable != null) {
        _selectedType = widget.receivable!.type;
        _titleController.text = widget.receivable!.title;
        _amountController.text = _amountFormat.format(widget.receivable!.amount);
        _fromWhomController.text = widget.receivable!.fromWhom;
        _selectedDate = widget.receivable!.expectedReturnDate;
        _lentDate = widget.receivable!.lentDate;
        _noteController.text = widget.receivable!.note;
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

  void _onReceivedAmountChanged(String value) {
      if (value.isEmpty) return;
      String rawValue = value.replaceAll(',', '');
      if (rawValue.isEmpty) return;
      double? number = double.tryParse(rawValue);
      if (number == null) return;
      String formatted = _amountFormat.format(number);
      if (value != formatted) {
          _receivedAmountController.value = TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
          );
      }
  }

  Future<void> _selectLentDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lentDate,
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
    );
    if (picked != null && picked != _lentDate) {
      setState(() {
        _lentDate = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
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

  void _saveReceivable() {
    final enteredTitle = _titleController.text;
    final enteredAmount = double.tryParse(_amountController.text.replaceAll(',', ''));
    final enteredReceivedAmount = double.tryParse(_receivedAmountController.text.replaceAll(',', '')) ?? 0.0;
    final enteredFromWhom = _fromWhomController.text;

    if (enteredTitle.isEmpty || enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount and title.')),
      );
      return;
    }

    if (enteredFromWhom.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter who this receivable is from.')),
        );
        return;
    }

    final provider = Provider.of<ReceivableProvider>(context, listen: false);

    if (widget.receivable != null) {
        // Update Logic
        final updatedReceivable = Receivable(
            id: widget.receivable!.id,
            title: enteredTitle,
            amount: enteredAmount,
            paymentHistory: widget.receivable!.paymentHistory,
            settlementHistory: widget.receivable!.settlementHistory,
            fromWhom: enteredFromWhom,
            expectedReturnDate: _selectedDate,
            lentDate: _lentDate,
            isSettled: widget.receivable!.isSettled,
            type: _selectedType,
            note: _noteController.text.trim(),
        );
        provider.updateReceivable(updatedReceivable);
    } else {
        // Create Logic
        final receivable = Receivable(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: enteredTitle,
          amount: enteredAmount,
          paymentHistory: [],
          settlementHistory: enteredReceivedAmount > 0 
              ? [ReceivableSettlement(amount: enteredReceivedAmount, date: DateTime.now(), note: _noteController.text.trim())]
              : [],
          fromWhom: enteredFromWhom,
          expectedReturnDate: _selectedDate,
          lentDate: _lentDate,
          type: _selectedType,
          note: _noteController.text.trim(),
        );
        provider.addReceivable(receivable);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.receivable != null;
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
          title: Text(isEditing ? 'Edit Receivable' : 'Add Receivable', style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 18)),
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

              // Type Selector
              FadeInSlide(
                delay: 0.05,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildTypeOption('Person', Icons.person),
                      _buildTypeOption('Card', Icons.credit_card),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              FadeInSlide(
                delay: 0.1,
                child: _buildInputField(
                  controller: _titleController,
                  hint: 'Title (e.g. Loan)',
                  icon: Icons.edit,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(height: 16),
              
              // From Whom
              FadeInSlide(
                delay: 0.15,
                child: _buildInputField(
                  controller: _fromWhomController,
                  hint: 'From Whom (e.g. John)',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
              const SizedBox(height: 16),
              
              // Received Amount - Hide in Edit Mode
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
                        controller: _receivedAmountController,
                         keyboardType: const TextInputType.numberWithOptions(decimal: true),
                         onChanged: _onReceivedAmountChanged,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Outfit'),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Received Amount (Optional)',
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          icon: const Icon(Icons.money_off, color: Colors.grey, size: 20),
                        ),
                      ),
                    ),
                  ),
              
              const SizedBox(height: 16),
              
              // Note Field
              FadeInSlide(
                delay: 0.25,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontFamily: 'Outfit'),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Note (Optional)',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      icon: const Icon(Icons.note_alt_outlined, color: Colors.grey, size: 20),
                    ),
                  ),
                ),
              ),
              if (!isEditing) const SizedBox(height: 16),
 
              // Lent Date Picker
              FadeInSlide(
                delay: 0.25,
                child: ScaleButton(
                  onTap: () => _selectLentDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Lent Date: ${DateFormat('d MMM yyyy').format(_lentDate)}',
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

              // Expected Return Date Picker
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
                        const Icon(Icons.event, color: Colors.grey, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Expected Return: ${DateFormat('d MMM yyyy').format(_selectedDate)}',
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
                  onTap: _saveReceivable,
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
                          isEditing ? 'Update Receivable' : 'Save Receivable',
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

  Widget _buildTypeOption(String type, IconData icon) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFC6F432) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey('${type}_icon_$isSelected'),
                  size: 20,
                  color: isSelected ? Colors.black : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 16,
                ),
                child: Text(type),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
