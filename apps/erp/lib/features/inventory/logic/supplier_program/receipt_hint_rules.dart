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

