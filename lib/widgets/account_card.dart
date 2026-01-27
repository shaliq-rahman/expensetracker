import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AccountCard extends StatelessWidget {
  final double balance;
  final String currency;
  final String validThru; // e.g., 05/28
  final String accountNumber; // e.g., **** 9934
  final bool isDark;

  const AccountCard({
    super.key,
    required this.balance,
    required this.currency,
    required this.validThru,
    required this.accountNumber,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.black : const Color(0xFFFDFDFD); // Off-white/Cream

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 5,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Currency Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text('US', style: TextStyle(fontSize: 6, color: Colors.white)),
                    ), // Flag placeholder
                    const SizedBox(width: 8),
                    Text(
                      currency,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Card Type Icon
              Icon(
                Icons.credit_card, // Placeholder for VISA/Mastercard logo
                color: textColor,
                size: 28,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your balance',
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text(
                NumberFormat.currency(symbol: '₹', decimalDigits: 2).format(balance),
                style: TextStyle(
                  color: textColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account number',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accountNumber,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Valid Thru',
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[500], fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    validThru,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
