import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Helper utility for safely launching native iOS/Android PDF Print & Share options.
///
/// On iOS 18 physical devices, opening native UIActivityViewController / AirPrint
/// immediately after dismissing a modal sheet causes UIViewController transition collisions.
/// This helper waits for modal dismissal transitions to finish and provides the [bounds]
/// popover anchor required by iOS.
abstract class SalesPdfRunner {
  /// Share PDF bytes safely with native OS Share Sheet.
  static Future<void> share({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;

    final box = context.findRenderObject() as RenderBox?;
    final bounds = (box != null && box.hasSize && box.attached)
        ? (box.localToGlobal(Offset.zero) & box.size)
        : Rect.zero;

    await Printing.sharePdf(
      bytes: bytes,
      filename: filename,
      bounds: bounds,
    );
  }

  /// Print PDF bytes safely with native OS Print Controller.
  static Future<void> print({
    required BuildContext context,
    required Uint8List bytes,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: name,
    );
  }
}
