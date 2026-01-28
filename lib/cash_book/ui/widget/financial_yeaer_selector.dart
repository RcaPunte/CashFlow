import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

class FinancialYear {
  final int startYear;
  final int endYear;

  FinancialYear(this.startYear) : endYear = startYear + 1;

  @override
  String toString() => "$startYear–$endYear";
}

final financialYearProvider = StateProvider<FinancialYear>((ref) {
  final now = DateTime.now();
  final fyStart = now.month >= 4 ? now.year : now.year - 1;
  // final fyStart = now.year; //for Jan-Dec financial year
  return FinancialYear(fyStart);
});

class FinancialYearSelector extends ConsumerWidget {
  const FinancialYearSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fy = ref.watch(financialYearProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar, size: 16),
            const SizedBox(width: 6),
            Text(
              fy.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 14),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final years = List.generate(7, (i) => FinancialYear(2022 + i));
    int index = years.indexWhere(
      (y) => y.startYear == ref.read(financialYearProvider).startYear,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Select Financial Year",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                CupertinoButton(
                  child: const Text(
                    "Done",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    ref.read(financialYearProvider.notifier).state =
                        years[index];
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 36,
                scrollController: FixedExtentScrollController(
                  initialItem: index,
                ),
                onSelectedItemChanged: (i) => index = i,
                children: years
                    .map((y) => Center(child: Text(y.toString())))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final yearProvider = StateProvider<int>((ref) {
  return DateTime.now().year; // default selected year
});

class YearSelector extends ConsumerWidget {
  const YearSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = ref.watch(yearProvider);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showPicker(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.calendar, size: 16),
            const SizedBox(width: 6),
            Text(
              year.toString(),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 4),
            const Icon(CupertinoIcons.chevron_down, size: 14),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final years = List.generate(10, (i) => DateTime.now().year - 5 + i);

    int selectedIndex = years.indexOf(ref.read(yearProvider));

    final controller = FixedExtentScrollController(
      initialItem: selectedIndex == -1 ? 0 : selectedIndex,
    );

    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        color: CupertinoColors.systemBackground,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Select Year",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Text(
                      "Done",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      ref.read(yearProvider.notifier).state =
                          years[selectedIndex];
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Picker
            Expanded(
              child: CupertinoPicker(
                scrollController: controller,
                itemExtent: 36,
                magnification: 1.1,
                useMagnifier: true,
                onSelectedItemChanged: (i) => selectedIndex = i,
                children: years
                    .map(
                      (y) => Center(
                        child: Text(
                          y.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------------------
/// MODEL
/// ----------------------------------------------
class OpeningBalance {
  final double generalAc;
  final double buildingAc;

  const OpeningBalance({required this.generalAc, required this.buildingAc});

  double get total => generalAc + buildingAc;

  OpeningBalance copyWith({double? generalAc, double? buildingAc}) {
    return OpeningBalance(
      generalAc: generalAc ?? this.generalAc,
      buildingAc: buildingAc ?? this.buildingAc,
    );
  }
}

/// ----------------------------------------------
/// PROVIDER
/// ----------------------------------------------
///
/// This provider returns opening balance
/// based on selected Financial Year
///
final openingBalanceProvider = Provider.family<OpeningBalance, FinancialYear>((
  ref,
  fy,
) {
  /*
   ─────────────────────────────────────
   OPTION 1️⃣ : STATIC (for now)
   ─────────────────────────────────────
   Replace this block with Supabase fetch
  */

  if (fy.startYear == 2024) {
    return const OpeningBalance(generalAc: 150000.00, buildingAc: 320000.00);
  }

  if (fy.startYear == 2025) {
    return const OpeningBalance(generalAc: 180000.00, buildingAc: 400000.00);
  }

  // Default fallback
  return const OpeningBalance(generalAc: 0, buildingAc: 0);
});

/// ----------------------------------------------
/// OPTIONAL 🔁
/// AUTO CARRY-FORWARD (Future Ready)
/// ----------------------------------------------
///
/// When you implement this:
/// - Closing balance of previous FY
/// - Becomes opening of next FY
///
/// Example logic (Supabase):
///
/// final prevFy = FinancialYear(fy.startYear - 1);
/// final closing = await fetchClosingBalance(prevFy);
///
/// return OpeningBalance(
///   generalAc: closing.generalAc,
///   buildingAc: closing.buildingAc,
/// );
///

// class FinancialYearSelector extends ConsumerWidget {
//   const FinancialYearSelector({super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final fy = ref.watch(financialYearProvider);

//     return CupertinoButton(
//       padding: EdgeInsets.zero,
//       onPressed: () => _showPicker(context, ref),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//         decoration: BoxDecoration(
//           color: CupertinoColors.systemGrey5,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             const Icon(CupertinoIcons.calendar, size: 16),
//             const SizedBox(width: 6),
//             Text(
//               fy.toString(),
//               style: const TextStyle(fontWeight: FontWeight.w600),
//             ),
//             const SizedBox(width: 4),
//             const Icon(CupertinoIcons.chevron_down, size: 14),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showPicker(BuildContext context, WidgetRef ref) {
//     final years = List.generate(7, (i) => FinancialYear(2022 + i));
//     int index = years.indexWhere(
//       (y) => y.startYear == ref.read(financialYearProvider).startYear,
//     );

//     showCupertinoModalPopup(
//       context: context,
//       builder: (_) => Container(
//         height: 300,
//         color: CupertinoColors.systemBackground,
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 CupertinoButton(
//                   child: const Text("Cancel"),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 const Text(
//                   "Select Financial Year",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 CupertinoButton(
//                   child: const Text(
//                     "Done",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   onPressed: () {
//                     ref.read(financialYearProvider.notifier).state =
//                         years[index];
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//             Expanded(
//               child: CupertinoPicker(
//                 itemExtent: 36,
//                 scrollController:
//                     FixedExtentScrollController(initialItem: index),
//                 onSelectedItemChanged: (i) => index = i,
//                 children: years
//                     .map((y) => Center(child: Text(y.toString())))
//                     .toList(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
