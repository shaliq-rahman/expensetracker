enum ExpenseCategory {
  food,
  travel,
  entertainment,
  bills,
  shopping,
  health,
  education,
  salary,
  freelance,
  savings,
  investment,
  other,
  emi,
  ccBill,
}

extension CategoryExtension on ExpenseCategory {
  String get name {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.bills:
        return 'Bills';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.salary:
        return 'Salary';
      case ExpenseCategory.freelance:
        return 'Freelance';
      case ExpenseCategory.savings:
        return 'Savings';
      case ExpenseCategory.investment:
        return 'Investment';
      case ExpenseCategory.other:
        return 'Other';
      case ExpenseCategory.emi:
        return 'EMI';
      case ExpenseCategory.ccBill:
        return 'CC Bill';
    }
  }

  String get iconPath {
    switch (this) {
      case ExpenseCategory.food:
        return 'assets/icons/food.png';
      case ExpenseCategory.travel:
        return 'assets/icons/transport.png';
      case ExpenseCategory.entertainment:
        return 'assets/icons/entertainment.png';
      case ExpenseCategory.bills:
        return 'assets/icons/bills.png';
      case ExpenseCategory.shopping:
        return 'assets/icons/shopping.png';
      case ExpenseCategory.health:
        return 'assets/icons/health.png';
      case ExpenseCategory.education:
        return 'assets/icons/education.png';
      case ExpenseCategory.salary:
        return 'assets/icons/salary.png';
      case ExpenseCategory.savings:
        return 'assets/icons/savings.png';
      case ExpenseCategory.freelance:
        return 'assets/icons/freelance.png';
      case ExpenseCategory.investment:
        return 'assets/icons/investment.png';
      case ExpenseCategory.other:
        return 'assets/icons/other.png';
      case ExpenseCategory.emi:
        return 'assets/icons/emi_payment.png';
      case ExpenseCategory.ccBill:
        return 'assets/icons/cc_bill_payment.png';
    }
  }

  bool get isIncome {
    switch (this) {
      case ExpenseCategory.salary:
      case ExpenseCategory.freelance:
      case ExpenseCategory.investment:
        return true;
      case ExpenseCategory.other:
        return true; 
      default:
        return false;
    }
  }

}
