import 'package:equatable/equatable.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_draft.dart';

/// Kiểm tra tính hợp lệ của một dòng hàng nháp
String? lineInvalidReason(
  ReceiptLineDraft line, {
  required List<KnownLot> knownLots,
}) {
  if (line.lots.isEmpty) {
    return 'Nhập số lượng nhận.';
  }

  if (line.product.isLotTracked) {
    final seenCodes = <String>{};
    for (final lot in line.lots) {
      final trimmed = lot.code.trim();
      if (trimmed.isEmpty) {
        return 'Nhập mã lô';
      }
      final lower = trimmed.toLowerCase();
      if (seenCodes.contains(lower)) {
        return 'Lô này đã được thêm';
      }
      seenCodes.add(lower);

      if (line.product.expiryRequired && lot.expiryText.trim().isEmpty) {
        return 'Nhập hạn dùng';
      }

      if (lot.expiryText.trim().isNotEmpty) {
        final exp = LotDate.tryParseAuto(lot.expiryText);
        if (exp == null) {
          return 'Hạn dùng chưa đúng dạng';
        }
      }

      if (lot.manufactureText.trim().isNotEmpty) {
        final mfg = LotDate.tryParseAuto(lot.manufactureText);
        if (mfg == null) {
          return 'Ngày sản xuất chưa đúng dạng';
        }
      }

      // Check known lots
      for (final known in knownLots) {
        if (known.productId == line.product.id &&
            known.code.trim().toLowerCase() == lower) {
          if (known.expiry != null && lot.expiryText.trim().isNotEmpty) {
            final exp = LotDate.tryParseAuto(lot.expiryText);
            if (exp != null && !exp.isConsistentWith(known.expiry!)) {
              return 'Lô ${lot.code} đã có hạn dùng ${known.expiry!.format()}';
            }
          }
        }
      }

      if (lot.quantity <= 0) {
        return 'Nhập số lượng nhận.';
      }
    }
  } else {
    for (final lot in line.lots) {
      if (lot.quantity <= 0) {
        return 'Nhập số lượng nhận.';
      }
    }
  }

  if (line.unitPriceVnd <= 0) {
    return 'Nhập giá mua.';
  }

  if (line.freeQty >= line.totalQuantity) {
    return 'SL tặng phải nhỏ hơn số lượng nhận';
  }

  if (line.tierPercent != null) {
    if (line.tierPercent! < 0 || line.tierPercent! > 100) {
      return 'Mức giảm từ 0 đến 100%';
    }
  }

  return null;
}

/// Tự động điền ưu đãi từ gợi ý chương trình NCC
ReceiptLineDraft applyHint(ReceiptLineDraft line, ProgramHint? hint) {
  if (hint == null) {
    return line.copyWith(
      clearProgramId: true,
      clearTierPercent: !line.tierEdited,
      clearHint: true,
    );
  }

  num freeQty = line.freeQty;
  double? tierPercent = line.tierPercent;

  switch (hint.kind) {
    case ProgramKind.buyXGetY:
      if (!line.tierEdited) {
        tierPercent = null;
      }
      if (!line.freeEdited && hint.suggestedFreeQty != null) {
        final suggested = hint.suggestedFreeQty!;
        final rate = line.unit.rate;
        if (rate > 0 && suggested % rate == 0) {
          freeQty = suggested ~/ rate;
        }
      }
    case ProgramKind.tierDiscount:
      if (!line.tierEdited && hint.tier != null) {
        tierPercent = hint.tier!.percent.toDouble();
      }
    case ProgramKind.volumeRebate:
      if (!line.tierEdited) {
        tierPercent = null;
      }
      break;
  }

  final shouldClearTier =
      !line.tierEdited && hint.kind != ProgramKind.tierDiscount;

  return line.copyWith(
    programId: hint.programId,
    hint: hint,
    freeQty: freeQty,
    tierPercent: tierPercent,
    clearTierPercent: shouldClearTier,
  );
}

/// Chuỗi tóm tắt ưu đãi trên dòng (ví dụ: 'Giảm 5% · tặng 1 hộp')
String? offerSummary(ReceiptLineDraft line) {
  final parts = <String>[];
  if (line.tierPercent != null && line.tierPercent! > 0) {
    final pctStr = line.tierPercent! % 1 == 0
        ? line.tierPercent!.toInt().toString()
        : line.tierPercent!.toString();
    parts.add('Giảm $pctStr%');
  }
  if (line.freeQty > 0) {
    final qtyStr = line.freeQty % 1 == 0
        ? line.freeQty.toInt().toString()
        : line.freeQty.toString();
    parts.add('tặng $qtyStr ${line.unit.name}');
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

class ReviewAttentionItem extends Equatable {
  const ReviewAttentionItem({
    required this.tone,
    required this.title,
    required this.message,
    required this.lineKey,
  });

  final VComponentTone tone;
  final String title;
  final String message;
  final String lineKey;

  @override
  List<Object?> get props => [tone, title, message, lineKey];
}

/// Trích xuất danh sách cần lưu ý khi rà soát phiếu nhận
List<ReviewAttentionItem> reviewAttention(List<ReceiptLineDraft> lines) {
  final items = <ReviewAttentionItem>[];

  for (final line in lines) {
    // 1. Gợi ý thay đổi so với lúc nhập
    if (line.hintAtEntry != null &&
        line.hint != null &&
        line.hintAtEntry!.programId != line.hint!.programId) {
      items.add(
        ReviewAttentionItem(
          tone: VComponentTone.warning,
          title: 'Ưu đãi đã cập nhật',
          message:
              'Ưu đãi cho ${line.product.name} đã thay đổi thành "${line.hint!.programName}".',
          lineKey: line.key,
        ),
      );
    }

    // 2. Sửa tay mức giảm
    if (line.tierEdited &&
        line.hint?.tier != null &&
        line.tierPercent != line.hint!.tier!.percent) {
      items.add(
        ReviewAttentionItem(
          tone: VComponentTone.warning,
          title: 'Đã sửa mức giảm',
          message:
              'Mức giảm của ${line.product.name} được sửa thành ${line.tierPercent}%.',
          lineKey: line.key,
        ),
      );
    }

    // 3. Tích lũy đạt mốc
    if (line.hint?.kind == ProgramKind.volumeRebate &&
        line.hint?.rebate?.wouldReach == true) {
      items.add(
        ReviewAttentionItem(
          tone: VComponentTone.info,
          title: 'Đạt mốc khi ghi phiếu',
          message:
              'Đơn hàng này giúp đạt mốc chương trình tích lũy "${line.hint!.programName}".',
          lineKey: line.key,
        ),
      );
    }
  }

  return items;
}
