class LedgerEntry {
  final String id;
  final String accountId;
  final String accountName;
  final DateTime date;
  final double amount;
  final String type; // 'debit' or 'credit'
  final String? description;

  LedgerEntry({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.date,
    required this.amount,
    required this.type,
    this.description,
  });

  factory LedgerEntry.fromMap(Map<String, dynamic> m) {
    return LedgerEntry(
      id: m['id'] as String,
      accountId: (m['account_id'] as String?) ?? '',
      accountName: (m['accounts'] != null && m['accounts']['name'] != null)
          ? m['accounts']['name'] as String
          : (m['account_name'] as String? ?? 'Unknown'),
      date: DateTime.parse(m['date'] as String),
      amount: (m['amount'] as num).toDouble(),
      type: m['type'] as String,
      description: m['description'] as String?,
    );
  }
}
