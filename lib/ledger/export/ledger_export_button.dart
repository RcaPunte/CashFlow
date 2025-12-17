import 'package:cashledger/ledger/export/ledger_pdf_export.dart';
import 'package:cashledger/ledger/model/ledger_entry.dart';
import 'package:flutter/cupertino.dart';

Widget ledgerExportButton({
  required BuildContext context,
  required List<LedgerEntry> entries,
  required double openingBalance,
}) {
  return CupertinoButton(
    child: const Icon(CupertinoIcons.share),
    // padding = EdgeInsets.zero,
    onPressed: () {
      showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          title: const Text('Export Ledger'),
          actions: [
            CupertinoActionSheetAction(
              child: const Text('Export as PDF'),
              onPressed: () {
                Navigator.pop(context);
                LedgerPdfExporter.export(
                  entries: entries,
                  title: 'Ledger Statement',
                  openingBalance: openingBalance,
                );
              },
            ),
            CupertinoActionSheetAction(
              child: const Text('Export as Excel'),
              onPressed: () {
                Navigator.pop(context);
                LedgerExcelExporter.export(
                  entries: entries,
                  openingBalance: openingBalance,
                );
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },

    // padding = EdgeInsets.zero,
  );
}
