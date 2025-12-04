import 'package:cashledger/cash_book/model/cash_book_filter.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ----------------------------------------------------------
// FILTER MODEL
// ----------------------------------------------------------
class CashbookFilter {
  final String sort;
  final String type;
  final String search;
  final DateTime? fromDate;
  final DateTime? toDate;

  const CashbookFilter({
    this.sort = "date_desc",
    this.type = "all",
    this.search = "",
    this.fromDate,
    this.toDate,
  });

  CashbookFilter copyWith({
    String? sort,
    String? type,
    String? search,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return CashbookFilter(
      sort: sort ?? this.sort,
      type: type ?? this.type,
      search: search ?? this.search,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

// ----------------------------------------------------------
// NOTIFIER
// ----------------------------------------------------------
class CashbookFilterNotifier extends StateNotifier<CashbookFilter> {
  CashbookFilterNotifier() : super(const CashbookFilter());

  void setSort(String value) => state = state.copyWith(sort: value);

  void setType(String value) => state = state.copyWith(type: value);

  void setSearch(String value) => state = state.copyWith(search: value);

  void setFromDate(DateTime? value) => state = state.copyWith(fromDate: value);

  void setToDate(DateTime? value) => state = state.copyWith(toDate: value);

  void clearFilters() => state = const CashbookFilter();
}

// ----------------------------------------------------------
// PROVIDER
// ----------------------------------------------------------
final cashbookFilterProvider =
    StateNotifierProvider<CashbookFilterNotifier, CashbookFilter>(
      (ref) => CashbookFilterNotifier(),
    );
