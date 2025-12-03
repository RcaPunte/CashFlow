class AccountModel {
  final String id;
  final String name;
  final String? description;
  final String accountType;
  final double? limitAmount;

  AccountModel({
    required this.id,
    required this.name,
    this.description,
    required this.accountType,
    this.limitAmount,
  });

  factory AccountModel.fromMap(Map<String, dynamic> m) {
    return AccountModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String?,
      accountType: m['account_type'] as String? ?? 'custom',
      limitAmount: m['limit_amount'] == null
          ? null
          : (m['limit_amount'] as num).toDouble(),
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'account_type': accountType,
      'limit_amount': limitAmount,
    };
  }
}
