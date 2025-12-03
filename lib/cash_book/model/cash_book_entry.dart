class EntryModel {
  final String id;
  final DateTime date;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String? category;
  final String? description;
  final String accountId; // FK to accounts.id

  EntryModel({
    required this.id,
    required this.date,
    required this.amount,
    required this.type,
    this.category,
    this.description,
    required this.accountId,
  });

  factory EntryModel.fromMap(Map<String, dynamic> m) {
    return EntryModel(
      id: m['id'] as String,
      date: DateTime.parse((m['date'] as String)),
      amount: (m['amount'] as num).toDouble(),
      type: m['type'] as String,
      category: m['category'] as String?,
      description: m['description'] as String?,
      accountId: m['account_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'type': type,
      'category': category,
      'description': description,
      'account_id': accountId,
    };
  }
}
