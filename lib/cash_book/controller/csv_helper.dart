// utils/csv_export.dart
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareCsvFromRows(List<List<dynamic>> rows, String fileName) async {
  final csv = const ListToCsvConverter().convert(rows);
  await Share.share(csv, subject: fileName);
}
