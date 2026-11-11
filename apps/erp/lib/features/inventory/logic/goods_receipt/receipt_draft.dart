import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_models.dart';
import 'package:erp/features/inventory/data/models/lot_date.dart';
import 'package:erp/features/inventory/data/supplier_program/supplier_program_models.dart';

/// Một lô trong một dòng hàng nháp
class ReceiptLotEntry extends Equatable {
  const ReceiptLotEntry({
    required this.key,
    required this.code,
    required this.expiryText,
    required this.manufactureText,
    required this.quantity,
  });

  final String key;
  final String code;
  final String expiryText;
  final String manufactureText;
  final num quantity;

  ReceiptLotEntry copyWith({
    String? key,
    String? code,
    String? expiryText,
    String? manufactureText,
    num? quantity,
  }) {
    return ReceiptLotEntry(
      key: key ?? this.key,
      code: code ?? this.code,
      expiryText: expiryText ?? this.expiryText,
      manufactureText: manufactureText ?? this.manufactureText,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [key, code, expiryText, manufactureText, quantity];
}

/// Một dòng hàng trong phiếu nhận
class ReceiptLineDraft extends Equatable {
  const ReceiptLineDraft({
    required this.key,
    required this.product,
    required this.unit,
    required this.unitPriceVnd,
    this.freeQty = 0,
    this.freeEdited = false,
    this.tierPercent,
    this.tierEdited = false,
    this.programId,
    required this.lots,
    this.hint,
    this.hintAtEntry,
  });

  final String key;
  final ReceiptProductOption product;
  final ReceiptUnitOption unit;
  final int unitPriceVnd;
  final num freeQty;
  final bool freeEdited;
  final double? tierPercent;
  final bool tierEdited;
  final String? programId;
  final List<ReceiptLotEntry> lots;
  final ProgramHint? hint;
  final ProgramHint? hintAtEntry;

  num get totalQuantity => lots.fold<num>(0, (acc, lot) => acc + lot.quantity);

  num get paidQuantity => (totalQuantity - freeQty).clamp(0, double.infinity);

  num get totalBaseQuantity => totalQuantity * unit.rate;

  ReceiptLineDraft copyWith({
    String? key,
    ReceiptProductOption? product,
    ReceiptUnitOption? unit,
    int? unitPriceVnd,
    num? freeQty,
    bool? freeEdited,
    double? tierPercent,
    bool clearTierPercent = false,
    bool? tierEdited,
    String? programId,
    bool clearProgramId = false,
    List<ReceiptLotEntry>? lots,
    ProgramHint? hint,
    bool clearHint = false,
    ProgramHint? hintAtEntry,
    bool clearHintAtEntry = false,
  }) {
    return ReceiptLineDraft(
      key: key ?? this.key,
      product: product ?? this.product,
      unit: unit ?? this.unit,
      unitPriceVnd: unitPriceVnd ?? this.unitPriceVnd,
      freeQty: freeQty ?? this.freeQty,
      freeEdited: freeEdited ?? this.freeEdited,
      tierPercent: clearTierPercent ? null : (tierPercent ?? this.tierPercent),
      tierEdited: tierEdited ?? this.tierEdited,
      programId: clearProgramId ? null : (programId ?? this.programId),
      lots: lots ?? this.lots,
      hint: clearHint ? null : (hint ?? this.hint),
      hintAtEntry: clearHintAtEntry ? null : (hintAtEntry ?? this.hintAtEntry),
    );
  }

  Map<String, dynamic> toPayload() {
    final lotPayloads = lots.map((lot) {
      if (!product.isLotTracked) {
        return <String, dynamic>{
          'lot_code': null,
          'expiry_date': null,
          'expiry_precision': null,
          'manufacture_date': null,
          'quantity': lot.quantity,
        };
      }

      final exp = LotDate.tryParseAuto(lot.expiryText);
      String? expDate;
      String? expPrecision;
      if (exp != null) {
        expDate =
            '${exp.year.toString().padLeft(4, '0')}-${(exp.month ?? 1).toString().padLeft(2, '0')}-${(exp.day ?? 1).toString().padLeft(2, '0')}';
        expPrecision = exp.precision.name.toUpperCase();
      }

      final mfg = LotDate.tryParseAuto(lot.manufactureText);
      String? mfgDate;
      if (mfg != null) {
        mfgDate =
            '${mfg.year.toString().padLeft(4, '0')}-${(mfg.month ?? 1).toString().padLeft(2, '0')}-${(mfg.day ?? 1).toString().padLeft(2, '0')}';
      }

      final trimmedCode = lot.code.trim();
      return <String, dynamic>{
        'lot_code': trimmedCode.isEmpty ? null : trimmedCode,
        'expiry_date': expDate,
        'expiry_precision': expPrecision,
        'manufacture_date': mfgDate,
        'quantity': lot.quantity,
      };
    }).toList();

    return <String, dynamic>{
      'product_id': product.id,
      'unit_id': unit.id,
      'unit_price_vnd': unitPriceVnd,
      'free_qty': freeQty,
      'tier_discount_percent':
          hint?.kind == ProgramKind.tierDiscount ? tierPercent : null,
      'program_id': programId,
      'lots': lotPayloads,
    };
  }

  @override
  List<Object?> get props => [
        key,
        product,
        unit,
        unitPriceVnd,
        freeQty,
        freeEdited,
        tierPercent,
        tierEdited,
        programId,
        lots,
        hint,
        hintAtEntry,
      ];
}

/// Toàn bộ phiếu nhận nháp
class ReceiptDraft extends Equatable {
  const ReceiptDraft({
    this.supplier,
    this.docNo = '',
    this.freightVnd = 0,
    this.discountVnd = 0,
    this.lines = const [],
    this.idempotencyKey,
  });

  final ReceiptSupplierOption? supplier;
  final String docNo;
  final int freightVnd;
  final int discountVnd;
  final List<ReceiptLineDraft> lines;
  final String? idempotencyKey;

  ReceiptDraft copyWith({
    ReceiptSupplierOption? supplier,
    String? docNo,
    int? freightVnd,
    int? discountVnd,
    List<ReceiptLineDraft>? lines,
    String? idempotencyKey,
    bool clearIdempotencyKey = false,
  }) {
    return ReceiptDraft(
      supplier: supplier ?? this.supplier,
      docNo: docNo ?? this.docNo,
      freightVnd: freightVnd ?? this.freightVnd,
      discountVnd: discountVnd ?? this.discountVnd,
      lines: lines ?? this.lines,
      idempotencyKey: clearIdempotencyKey ? null : (idempotencyKey ?? this.idempotencyKey),
    );
  }

  Map<String, dynamic> toPayload() {
    final cleanDoc = docNo.trim();
    return <String, dynamic>{
      'supplier_id': supplier?.id,
      'supplier_doc_no': cleanDoc.isEmpty ? null : cleanDoc,
      'freight_cost_vnd': freightVnd,
      'trade_discount_vnd': discountVnd,
      'lines': lines.map((l) => l.toPayload()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        supplier,
        docNo,
        freightVnd,
        discountVnd,
        lines,
        idempotencyKey,
      ];
}
