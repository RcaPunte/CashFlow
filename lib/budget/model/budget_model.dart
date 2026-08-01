/// Budget types as used by Mizo NGOs
enum BudgetType {
  annual,
  supplementary,
  emergency,
  revised;

  String get label {
    switch (this) {
      case BudgetType.annual:
        return 'Annual';
      case BudgetType.supplementary:
        return 'Supplementary';
      case BudgetType.emergency:
        return 'Emergency';
      case BudgetType.revised:
        return 'Revised';
    }
  }
}

/// Year type for budget period
enum YearType {
  calendar,
  financial;

  String get label {
    switch (this) {
      case YearType.calendar:
        return 'Calendar Year (Jan–Dec)';
      case YearType.financial:
        return 'Financial Year (Apr–Mar)';
    }
  }

  String get shortLabel {
    switch (this) {
      case YearType.calendar:
        return 'Calendar';
      case YearType.financial:
        return 'Financial';
    }
  }
}

/// Budget status reflecting committee workflow
enum BudgetStatus {
  draft,
  submitted,
  approved,
  rejected;

  String get label {
    switch (this) {
      case BudgetStatus.draft:
        return 'Draft';
      case BudgetStatus.submitted:
        return 'Submitted';
      case BudgetStatus.approved:
        return 'Approved';
      case BudgetStatus.rejected:
        return 'Rejected';
    }
  }
}

class Budget {
  final String id;
  final String name;
  final int year;
  final YearType yearType;
  final BudgetType type;
  final BudgetStatus status;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final String userId;

  /// NULL = org-wide budget; non-NULL = department/account-specific budget
  final String? accountId;
  final String? accountName;

  /// Manual opening balance for this budget period
  final double? openingBalance;

  Budget({
    required this.id,
    required this.name,
    required this.year,
    required this.yearType,
    required this.type,
    required this.status,
    this.notes,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.userId,
    this.accountId,
    this.accountName,
    this.openingBalance,
  });

  /// Returns the display label for the year period
  String get yearLabel {
    if (yearType == YearType.financial) {
      return 'FY $year-${(year + 1).toString().substring(2)}';
    }
    return '$year';
  }

  /// Returns the full date range for this budget
  String get dateRange {
    if (yearType == YearType.financial) {
      return 'Apr $year – Mar ${year + 1}';
    }
    return 'Jan $year – Dec $year';
  }

  /// Start date of the budget period
  DateTime get periodStart {
    if (yearType == YearType.financial) {
      return DateTime(year, 4, 1);
    }
    return DateTime(year, 1, 1);
  }

  /// End date of the budget period (inclusive)
  DateTime get periodEnd {
    if (yearType == YearType.financial) {
      return DateTime(year + 1, 3, 31, 23, 59, 59);
    }
    return DateTime(year, 12, 31, 23, 59, 59);
  }

  /// Returns the previous period for baseline comparison
  ({DateTime from, DateTime to}) get previousPeriod {
    if (yearType == YearType.financial) {
      return (
        from: DateTime(year - 1, 4, 1),
        to: DateTime(year, 3, 31, 23, 59, 59),
      );
    }
    return (
      from: DateTime(year - 1, 1, 1),
      to: DateTime(year - 1, 12, 31, 23, 59, 59),
    );
  }

  factory Budget.fromMap(Map<String, dynamic> m) {
    return Budget(
      id: m['id'] as String,
      name: m['name'] as String,
      year: (m['year'] is int) ? m['year'] : int.parse(m['year'].toString()),
      yearType: m['year_type'] == 'financial' ? YearType.financial : YearType.calendar,
      type: BudgetType.values.firstWhere(
        (e) => e.name == (m['type'] as String?) || e.name == (m['budget_type'] as String?),
        orElse: () => BudgetType.annual,
      ),
      status: BudgetStatus.values.firstWhere(
        (e) => e.name == (m['status'] as String?),
        orElse: () => BudgetStatus.draft,
      ),
      notes: m['notes'] as String?,
      approvedBy: m['approved_by'] as String?,
      approvedAt: m['approved_at'] != null ? DateTime.tryParse(m['approved_at'] as String) : null,
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
      userId: (m['user_id'] as String?) ?? '',
      accountId: m['account_id'] as String?,
      accountName: m['account_name'] as String? ?? m['accounts']?['name'] as String?,
      openingBalance: m['opening_balance'] != null
          ? (m['opening_balance'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'year_type': yearType.name,
      'type': type.name,
      'status': status.name,
      'account_id': accountId,
      'notes': notes,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'opening_balance': openingBalance,
    };
  }

  Budget copyWith({
    String? id,
    String? name,
    int? year,
    YearType? yearType,
    BudgetType? type,
    BudgetStatus? status,
    String? notes,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? createdAt,
    String? userId,
    String? accountId,
    String? accountName,
    double? openingBalance,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      year: year ?? this.year,
      yearType: yearType ?? this.yearType,
      type: type ?? this.type,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      openingBalance: openingBalance ?? this.openingBalance,
    );
  }
}