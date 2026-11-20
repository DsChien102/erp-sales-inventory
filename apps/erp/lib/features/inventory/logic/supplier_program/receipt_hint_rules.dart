import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/supplier_program_rules.dart';

/// Dựng các dòng gợi ý ưu đãi NCC trên dòng phiếu nhận (mục 2.3 "Gợi ý").
List<String> hintLines(
  ProgramHint h,
  String uom, {
  num paidQty = 0,
}) {
  final lines = <String>[];
  switch (h.kind) {
    case ProgramKind.tierDiscount:
      if (h.tier != null) {
        lines.add(
          'Đang áp bậc từ ${formatProgramQuantity(h.tier!.minQty)}: giảm ${formatPercent(h.tier!.percent)}%',
        );
      }
      if (h.nextTier != null) {
        lines.add(
          'Nhập thêm ${formatProgramQuantity(h.nextTier!.missingQty)} $uom để được giảm ${formatPercent(h.nextTier!.percent)}%',
        );
      }
    case ProgramKind.buyXGetY:
      final n = h.suggestedFreeQty ?? 0;
      final buy = h.buyQty ?? 0;
      final free = h.freeQty ?? 0;
      if (n <= 0) {
        lines.add(
          'Mua đủ ${formatProgramQuantity(buy)} $uom để được tặng ${formatProgramQuantity(free)}',
        );
      } else {
        lines.add(
          'Tặng ${formatProgramQuantity(n)} $uom (mua ${formatProgramQuantity(buy)} tặng ${formatProgramQuantity(free)})',
        );
      }
    case ProgramKind.volumeRebate:
      final r = h.rebate;
      if (r != null) {
        final suffix = r.wouldReach ? ' — đạt mốc khi ghi phiếu' : '';
        lines.add(
          'Tính vào chương trình "${h.programName}": ${formatProgramQuantity(r.progress)} + ${formatProgramQuantity(paidQty)} / ${formatProgramQuantity(r.target)} $uom$suffix',
        );
      }
  }
  return lines;
}

/// Dòng ước tính chiết khấu đạt mốc ngay trên dòng phiếu nhận (plan G5-5c, tính trên UI).
///
/// `paidQty` và `unitPrice` đã quy về ĐVT cơ sở. Chỉ là xấp xỉ: coi toàn bộ tiền mua của
/// chương trình bằng `mốc × đơn giá`, không tính hàng đang tồn và các lần nhập trước có giá khác.
List<String> rebateEstimateLines(
  ProgramHint hint,
  num? rebatePercent,
  String uom, {
  required num paidQty,
  required num unitPrice,
}) {
  final r = hint.rebate;
  if (hint.kind != ProgramKind.volumeRebate || r == null) return const [];

  final lines = <String>[];
  final missing = r.target - r.progress - paidQty;
  if (missing > 0) {
    lines.add(
      'Còn thiếu ${formatProgramQuantity(missing)} $uom để đạt mốc ${formatProgramQuantity(r.target)}.',
    );
  }
  if (rebatePercent != null && unitPrice > 0) {
    final estimate = (r.target * unitPrice * rebatePercent / 100).round();
    final avgExpected = (unitPrice * (1 - rebatePercent / 100)).round();
    lines.add(
      'Nếu nhập đủ mốc với đơn giá này: giảm ${formatPercent(rebatePercent)}% ≈ ${MoneyFormatter.formatMinorPlain(estimate)} đ.',
    );
    lines.add(
      'Giá vốn dự kiến ≈ ${MoneyFormatter.formatMinor(avgExpected)}/$uom. Dự kiến, chưa ghi sổ; chưa tính hàng đang tồn.',
    );
  }
  return lines;
}
