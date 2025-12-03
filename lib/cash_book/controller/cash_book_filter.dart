import 'package:cashledger/cash_book/model/cash_book_filter.dart';
import 'package:flutter_riverpod/legacy.dart';

final cashbookFilterProvider = StateProvider.autoDispose<CashbookFilter>(
  (ref) => CashbookFilter(),
);
