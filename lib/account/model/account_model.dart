class AccountModel {
  final String id;
  final String name;
  final String? description;
  final String accountType;
  final double? limitAmount;
  final String? limitPeriod;
  final String? parentId;
  final int year;
  final String userId;
  AccountModel({
    required this.id,
    required this.name,
    this.description,
    required this.accountType,
    this.limitAmount,
    this.limitPeriod,
    this.parentId,
    this.year = 2026,
    required this.userId,
  });

  factory AccountModel.fromMap(Map<String, dynamic> m) {
    try {
      return AccountModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        accountType: (m['account_type'] as String?) ?? 'custom',
        limitAmount: m['limit_amount'] != null
            ? (m['limit_amount'] as num).toDouble()
            : null,
        limitPeriod: m['limit_period'] as String?,
        parentId: m['parent_account_id'] as String?,
        year: (m['year'] is int) ? m['year'] : int.tryParse(m['year'].toString()) ?? 2026,
        userId: (m['user_id'] as String?) ?? '',
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
      'limit_period': limitPeriod,
      'parent_account_id': parentId,
      'year': year,
      'user_id': userId,
    };
  }

  AccountModel copyWith({
    String? id,
    String? name,
    String? description,
    String? accountType,
    double? limitAmount,
    String? limitPeriod,
    String? parentId,
    int? year,
    String? userId,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      accountType: accountType ?? this.accountType,
      limitAmount: limitAmount ?? this.limitAmount,
      limitPeriod: limitPeriod ?? this.limitPeriod,
      parentId: parentId ?? this.parentId,
      year: year ?? this.year,
      userId: userId ?? this.userId,
    );
  }
}