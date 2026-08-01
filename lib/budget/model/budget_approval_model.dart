/// Audit trail entry for budget approval workflow
class BudgetApproval {
  final String id;
  final String budgetId;
  final BudgetApprovalAction action;
  final String userId;
  final String? comment;
  final DateTime createdAt;

  BudgetApproval({
    required this.id,
    required this.budgetId,
    required this.action,
    required this.userId,
    this.comment,
    required this.createdAt,
  });

  String get actionLabel {
    switch (action) {
      case BudgetApprovalAction.submitted:
        return 'Submitted for approval';
      case BudgetApprovalAction.approved:
        return 'Approved';
      case BudgetApprovalAction.rejected:
        return 'Rejected';
      case BudgetApprovalAction.revised:
        return 'Revised';
    }
  }

  factory BudgetApproval.fromMap(Map<String, dynamic> m) {
    return BudgetApproval(
      id: m['id'] as String,
      budgetId: m['budget_id'] as String,
      action: BudgetApprovalAction.values.firstWhere(
        (e) => e.name == (m['action'] as String?),
        orElse: () => BudgetApprovalAction.submitted,
      ),
      userId: (m['user_id'] as String?) ?? '',
      comment: m['comment'] as String?,
      createdAt: m['created_at'] != null
          ? DateTime.parse(m['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'budget_id': budgetId,
      'action': action.name,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum BudgetApprovalAction {
  submitted,
  approved,
  rejected,
  revised;
}