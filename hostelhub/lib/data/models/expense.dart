/// A one-off or recurring expense logged by the owner.
class Expense {
  final String id;
  final String propertyId;
  final String category; // groceries | salary | electricity | water | maintenance | misc
  final int amount;
  final String date;
  final String notes;

  const Expense({
    required this.id,
    required this.propertyId,
    required this.category,
    required this.amount,
    required this.date,
    this.notes = '',
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        propertyId: json['property_id'] as String,
        category: json['category'] as String,
        amount: json['amount'] as int,
        date: json['date'] as String,
        notes: json['notes'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'property_id': propertyId,
        'category': category,
        'amount': amount,
        'date': date,
        'notes': notes,
      };
}

/// Income vs expense summary for a property.
class Pnl {
  final int income;
  final int expense;
  final int net;
  final Map<String, int> expenseByCategory;

  const Pnl({
    required this.income,
    required this.expense,
    required this.net,
    this.expenseByCategory = const {},
  });

  factory Pnl.fromJson(Map<String, dynamic> json) => Pnl(
        income: json['income'] as int? ?? 0,
        expense: json['expense'] as int? ?? 0,
        net: json['net'] as int? ?? 0,
        expenseByCategory: Map<String, int>.from(
            json['expense_by_category'] as Map? ?? const {}),
      );
}
