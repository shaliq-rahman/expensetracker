enum ExpenseCategory {
  food,
  transport,
  entertainment,
  bills,
  shopping,
  health,
  education,
  salary,
  investment,
  other,
}

extension CategoryExtension on ExpenseCategory {
  String get name {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
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
      case ExpenseCategory.investment:
        return 'Investment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  bool get isIncome {
    switch (this) {
      case ExpenseCategory.salary:
      case ExpenseCategory.investment:
        return true;
      case ExpenseCategory.other:
        return true; // value can be both? For simplicity let's say other is always expense for now or handle it.
                     // Actually, 'other' is ambiguous. Let's strictly define.
      default:
        return false;
    }
  }
}
