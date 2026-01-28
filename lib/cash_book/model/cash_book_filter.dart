class CashbookFilter {
  String search = "";
  String sort =
      "date_desc"; // date_asc, date_desc, amount_asc, amount_desc, desc_asc, desc_desc
  DateTime? fromDate;
  DateTime? toDate;
  String type = "all"; // all, debit, credit

  CashbookFilter();
}
