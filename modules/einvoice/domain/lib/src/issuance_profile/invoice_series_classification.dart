import 'package:equatable/equatable.dart';

/// Classification of a MISA `InvSeries` per §1.6.
///
/// - Index 1 (2nd char): `C` = có mã CQT, `K` = không mã
/// - Index 4 (5th char): `M` = hóa đơn máy tính tiền (MTT)
final class InvoiceSeriesClassification extends Equatable {
  const InvoiceSeriesClassification({
    required this.invoiceWithCode,
    required this.isMtt,
  });

  final bool invoiceWithCode;
  final bool isMtt;

  /// Returns null when [invSeries] cannot be classified safely.
  static InvoiceSeriesClassification? tryParse(String invSeries) {
    final normalized = invSeries.trim().toUpperCase();
    if (normalized.length < 5) {
      return null;
    }
    final typeChar = normalized[0];
    if (typeChar != '1' && typeChar != '2' && typeChar != '5' && typeChar != '6') {
      return null;
    }
    final codeChar = normalized[1];
    if (codeChar != 'C' && codeChar != 'K') {
      return null;
    }
    final usageChar = normalized[4];
    if (usageChar != 'T' && usageChar != 'M') {
      return null;
    }
    return InvoiceSeriesClassification(
      invoiceWithCode: codeChar == 'C',
      isMtt: usageChar == 'M',
    );
  }

  @override
  List<Object?> get props => [invoiceWithCode, isMtt];
}
