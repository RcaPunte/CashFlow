class AccountModel {
  final String id;
  final String name;
  final String? description;
  final String accountType;
  final double? limitAmount;
  final String? parentId;
  final int year;
  final bool isLocked;
  AccountModel({
    required this.id,
    required this.name,
    this.description,
    required this.accountType,
    this.limitAmount,
    this.parentId,
    this.year = 2026,
    this.isLocked = false,
  });

  factory AccountModel.fromMap(Map<String, dynamic> m) {
    try {
      return AccountModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        accountType: m['account_type'] as String,
        limitAmount: m['limit_amount'] != null
            ? (m['limit_amount'] as num).toDouble()
            : null,
        parentId: m['parent_account_id'] as String?,
        year: m['year'] ?? 2026,
        isLocked: m['is_locked'] as bool? ?? false,
      );
    } catch (e) {
      throw Exception('Error parsing AccountModel: $e');
    }
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'account_type': accountType,
      'limit_amount': limitAmount,
      'parent_account_id': parentId,
      'year': year,
      'is_locked': isLocked,
    };
  }
}
