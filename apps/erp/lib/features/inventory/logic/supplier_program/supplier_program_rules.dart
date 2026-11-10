import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';
import 'package:erp/features/inventory/logic/supplier_program/program_form_draft.dart';
import 'package:vet45_design_system/design_system.dart';

/// Định dạng số lượng cho chương trình NCC (nhóm hàng nghìn bằng dấu chấm: 1.000;
/// phần lẻ tối đa 3 chữ số, ngăn cách bằng dấu phẩy: 1,5).
String formatProgramQuantity(num q) {
  final d = q.toDouble();
  if (d == d.roundToDouble()) {
    return _groupInteger(d.toInt());
  }
  final parts = d
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .split('.');
  final intPart = _groupInteger(int.tryParse(parts[0]) ?? 0);
  if (parts.length == 1 || parts[1].isEmpty) {
    return intPart;
  }
  return '$intPart,${parts[1]}';
}

String _groupInteger(int n) {
  final isNegative = n < 0;
  final digits = n.abs().toString();
  final buffer = StringBuffer();
  if (isNegative) buffer.write('-');
  for (var i = 0; i < digits.length; i++) {
    final fromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) {
      buffer.write('.');
    }
  }
  return buffer.toString();
}

/// Định dạng phần trăm bỏ số 0 thừa, dấu phẩy thập phân ("2,5", "5").
String formatPercent(num p) {
  final d = p.toDouble();
  if (d == d.roundToDouble()) return d.toInt().toString();
  return d
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceAll('.', ',');
}

String programStatusLabel(ProgramStatus status) => switch (status) {
      ProgramStatus.active => 'Đang chạy',
      ProgramStatus.reached => 'Đạt mốc',
      ProgramStatus.recorded => 'Đã ghi nhận',
      ProgramStatus.ended => 'Kết thúc',
    };

VComponentTone programStatusTone(ProgramStatus status) => switch (status) {
      ProgramStatus.active => VComponentTone.info,
      ProgramStatus.reached => VComponentTone.warning,
      ProgramStatus.recorded => VComponentTone.success,
      ProgramStatus.ended => VComponentTone.neutral,
    };

String programKindShort(ProgramKind kind) => switch (kind) {
      ProgramKind.tierDiscount => 'Giảm theo bậc',
      ProgramKind.buyXGetY => 'Mua X tặng Y',
      ProgramKind.volumeRebate => 'Chiết khấu đạt mốc',
    };

String programKindLong(ProgramKind kind) => switch (kind) {
      ProgramKind.tierDiscount => 'Giảm giá theo bậc số lượng',
      ProgramKind.buyXGetY => 'Mua X tặng Y',
      ProgramKind.volumeRebate => 'Chiết khấu đạt mốc số lượng tích luỹ',
    };

/// Tóm tắt một dòng (mục 2.3):
/// - Loại 1: "Từ 100 hộp giảm 3% · từ 300 giảm 5%" (bỏ ĐVT khi commonUom null)
/// - Loại 2: "Mua 10 tặng 1 hộp"
/// - Loại 3: "Đạt 1.000 hộp giảm 5% tổng tiền mua"
String programSummary(ProgramRow r) {
  final u = (r.commonUom != null && r.commonUom!.trim().isNotEmpty)
      ? ' ${r.commonUom!.trim()}'
      : '';
  return switch (r.kind) {
    ProgramKind.tierDiscount => [
        for (var i = 0; i < r.tiers.length; i++)
          if (i == 0)
            'Từ ${formatProgramQuantity(r.tiers[i].minQty)}$u giảm ${formatPercent(r.tiers[i].discountPercent)}%'
          else
            'từ ${formatProgramQuantity(r.tiers[i].minQty)} giảm ${formatPercent(r.tiers[i].discountPercent)}%',
      ].join(' · '),
    ProgramKind.buyXGetY =>
      'Mua ${formatProgramQuantity(r.buyQty ?? 0)} tặng ${formatProgramQuantity(r.freeQty ?? 0)}$u',
    ProgramKind.volumeRebate =>
      'Đạt ${formatProgramQuantity(r.targetQty ?? 0)}$u giảm ${formatPercent(r.rebatePercent ?? 0)}% tổng tiền mua',
  };
}

/// Kiểm tra form P2 theo bảng mục 2.3.
Map<String, String> validateProgramForm(
  ProgramFormDraft d,
  List<ProductOption> products, {
  DateTime? today,
}) {
  final errors = <String, String>{};

  // 1. Nhà cung cấp
  if (d.supplierId == null || d.supplierId!.trim().isEmpty) {
    errors['supplier'] = 'Chọn nhà cung cấp';
  }

  // 2. Tên
  final trimmedName = d.name.trim();
  if (trimmedName.isEmpty) {
    errors['name'] = 'Nhập tên chương trình';
  } else if (trimmedName.length > 120) {
    errors['name'] = 'Tên tối đa 120 ký tự';
  }

  // 3. Sản phẩm
  if (d.productIds.isEmpty) {
    errors['products'] = 'Chọn ít nhất một sản phẩm';
  } else if (d.kind == ProgramKind.buyXGetY && d.productIds.length != 1) {
    errors['products'] = 'Mua X tặng Y chỉ áp cho một sản phẩm';
  } else if (d.kind == ProgramKind.volumeRebate && d.productIds.length > 1) {
    final byId = {for (final p in products) p.productId: p};
    final firstProduct = byId[d.productIds.first];
    if (firstProduct != null) {
      final firstUomKey = firstProduct.baseUom.trim().toLowerCase();
      final hasMismatch = d.productIds.skip(1).any((pid) {
        final p = byId[pid];
        if (p == null) return false;
        final uomKey = p.baseUom.trim().toLowerCase();
        return uomKey != firstUomKey;
      });
      if (hasMismatch) {
        errors['products'] =
            'Các sản phẩm phải cùng đơn vị tính cơ sở (${firstProduct.baseUom})';
      }
    }
  }

  // 4. Tham số theo loại
  switch (d.kind) {
    case ProgramKind.tierDiscount:
      if (d.tiers.isEmpty || d.tiers.length > 5) {
        errors['tiers'] = 'Nhập số lượng và mức giảm';
      }
      num? prevQty;
      num? prevPct;
      for (var i = 0; i < d.tiers.length; i++) {
        final tier = d.tiers[i];
        final q = ProgramFormDraft.parseNum(tier.minQty);
        final pct = ProgramFormDraft.parseNum(tier.percent);
        if (q == null || pct == null || q <= 0) {
          errors['tier.$i'] = 'Nhập số lượng và mức giảm';
          continue;
        }
        if (pct < 0.01 ||
            pct > 100 ||
            !RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(tier.percent.trim())) {
          errors['tier.$i'] = 'Mức giảm từ 0,01 đến 100%';
          continue;
        }
        if (prevQty != null && q <= prevQty) {
          errors['tier.$i'] = 'Số lượng bậc sau phải lớn hơn bậc trước';
          prevQty = q;
          prevPct = pct;
          continue;
        }
        if (prevPct != null && pct <= prevPct) {
          errors['tier.$i'] = 'Mức giảm bậc sau phải lớn hơn bậc trước';
          prevQty = q;
          prevPct = pct;
          continue;
        }
        prevQty = q;
        prevPct = pct;
      }
    case ProgramKind.buyXGetY:
      final b = int.tryParse(d.buyQty.trim());
      if (b == null || b < 1) {
        errors['buyQty'] = 'Nhập số lượng mua';
      }
      final f = int.tryParse(d.freeQty.trim());
      if (f == null || f < 1) {
        errors['freeQty'] = 'Nhập số lượng tặng';
      }
    case ProgramKind.volumeRebate:
      final t = ProgramFormDraft.parseNum(d.targetQty);
      if (t == null || t <= 0) {
        errors['targetQty'] = 'Nhập mốc số lượng';
      }
      if (d.rebatePercent.trim().isEmpty) {
        errors['rebatePercent'] = 'Nhập % chiết khấu';
      } else {
        final r = ProgramFormDraft.parseNum(d.rebatePercent);
        if (r == null ||
            r < 0.01 ||
            r > 100 ||
            !RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(d.rebatePercent.trim())) {
          errors['rebatePercent'] = 'Mức giảm từ 0,01 đến 100%';
        }
      }
  }

  // 5. Ngày bắt đầu (±365 ngày)
  final refNow = today ?? DateTime.now();
  final refDay = DateTime(refNow.year, refNow.month, refNow.day);
  final startDay = DateTime(
    d.startedOn.year,
    d.startedOn.month,
    d.startedOn.day,
  );
  final diffDays = startDay.difference(refDay).inDays.abs();
  if (diffDays > 365) {
    errors['startedOn'] = 'Ngày bắt đầu trong vòng một năm so với hôm nay';
  }

  return errors;
}

