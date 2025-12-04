import 'dart:io';
import 'dart:ui';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

Future<void> shareReportAsImage(GlobalKey repaintKey) async {
  RenderRepaintBoundary boundary =
      repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

  final image = await boundary.toImage(pixelRatio: 3.0);
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  final bytes = byteData!.buffer.asUint8List();

  final dir = await getTemporaryDirectory();
  final file = File("${dir.path}/report.png");
  await file.writeAsBytes(bytes);

  await Share.shareXFiles([XFile(file.path)], text: "Monthly Cashbook Report");
}
