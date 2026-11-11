import 'package:equatable/equatable.dart';

class ReceiptCostLineInput extends Equatable {
  const ReceiptCostLineInput({
    required this.paidQty,
    required this.freeQty,
    required this.rate,
    required this.unitPriceVnd,
    this.tierPercent,
    required this.lotQuantities,
  });

  final num paidQty;
  final num freeQty;
  final double rate;
  final int unitPriceVnd;
  final double? tierPercent;
  final List<num> lotQuantities;

  @override
  List<Object?> get props => [
        paidQty,
        freeQty,
        rate,
        unitPriceVnd,
        tierPercent,
        lotQuantities,
      ];
}

class ReceiptCostLine extends Equatable {
  const ReceiptCostLine({
    required this.gross,
    required this.tierDiscount,
    required this.purchase,
    required this.freight,
    required this.discount,
    required this.landed,
    required this.landedUnitCost,
    required this.lotAmounts,
  });

  final int gross;
  final int tierDiscount;
  final int purchase;
  final int freight;
  final int discount;
  final int landed;
  final double landedUnitCost;
  final List<int> lotAmounts;

  @override
  List<Object?> get props => [
        gross,
        tierDiscount,
        purchase,
        freight,
        discount,
        landed,
        landedUnitCost,
        lotAmounts,
      ];
}

class ReceiptCostBreakdown extends Equatable {
  const ReceiptCostBreakdown({
    required this.purchaseTotal,
    required this.landedTotal,
    required this.discountTooLarge,
    required this.lines,
  });

  final int purchaseTotal;
  final int landedTotal;
  final bool discountTooLarge;
  final List<ReceiptCostLine> lines;

  @override
  List<Object?> get props => [
        purchaseTotal,
        landedTotal,
        discountTooLarge,
        lines,
      ];
}

ReceiptCostBreakdown computeReceiptCost(
  List<ReceiptCostLineInput> inputs, {
  required int freightVnd,
  required int discountVnd,
}) {
  if (inputs.isEmpty) {
    final landedTotal = freightVnd - discountVnd;
    return ReceiptCostBreakdown(
      purchaseTotal: 0,
      landedTotal: landedTotal,
      discountTooLarge: discountVnd > freightVnd,
      lines: const [],
    );
  }

  // 1. Tính gross, tierDiscount, purchase cho từng dòng
  final grossList = <int>[];
  final tierDiscountList = <int>[];
  final purchaseList = <int>[];
  int purchaseTotal = 0;

  for (final inp in inputs) {
    final gross = (inp.paidQty * inp.unitPriceVnd).round();
    final tier = inp.tierPercent != null
        ? (gross * inp.tierPercent! / 100.0).round()
        : 0;
    final purchase = gross - tier;
    grossList.add(gross);
    tierDiscountList.add(tier);
    purchaseList.add(purchase);
    purchaseTotal += purchase;
  }

  final landedTotal = purchaseTotal + freightVnd - discountVnd;
  final discountTooLarge = discountVnd > (purchaseTotal + freightVnd);

  // 2. Tìm index của dòng có purchase lớn nhất (hòa thì lấy index nhỏ nhất)
  int maxPurchaseIdx = 0;
  for (int i = 1; i < purchaseList.length; i++) {
    if (purchaseList[i] > purchaseList[maxPurchaseIdx]) {
      maxPurchaseIdx = i;
    }
  }

  // 3. Phân bổ freight và discount
  final freightList = List<int>.filled(inputs.length, 0);
  final discountList = List<int>.filled(inputs.length, 0);

  if (purchaseTotal > 0) {
    int sumFreight = 0;
    int sumDiscount = 0;
    for (int i = 0; i < inputs.length; i++) {
      final f = (freightVnd * purchaseList[i]) ~/ purchaseTotal;
      final d = (discountVnd * purchaseList[i]) ~/ purchaseTotal;
      freightList[i] = f;
      discountList[i] = d;
      sumFreight += f;
      sumDiscount += d;
    }
    freightList[maxPurchaseIdx] += (freightVnd - sumFreight);
    discountList[maxPurchaseIdx] += (discountVnd - sumDiscount);
  } else {
    // purchaseTotal == 0 thì toàn bộ freight và discount vào dòng đầu tiên
    freightList[0] = freightVnd;
    discountList[0] = discountVnd;
  }

  // 4. Tính landed, landedUnitCost, lotAmounts cho từng dòng
  final lines = <ReceiptCostLine>[];
  for (int i = 0; i < inputs.length; i++) {
    final inp = inputs[i];
    final landed = purchaseList[i] + freightList[i] - discountList[i];
    final baseTotalQty = (inp.paidQty + inp.freeQty) * inp.rate;
    final landedUnitCost =
        baseTotalQty > 0 ? (landed / baseTotalQty) : 0.0;

    // Phân bổ tiền từng lô
    final lotAmounts = List<int>.filled(inp.lotQuantities.length, 0);
    final totalLotQty = inp.lotQuantities.fold<num>(0, (a, b) => a + b);

    if (inp.lotQuantities.isNotEmpty) {
      if (totalLotQty > 0) {
        int sumLot = 0;
        int maxLotIdx = 0;
        for (int j = 0; j < inp.lotQuantities.length; j++) {
          final amt = (landed * inp.lotQuantities[j]) ~/ totalLotQty;
          lotAmounts[j] = amt;
          sumLot += amt;
          if (inp.lotQuantities[j] > inp.lotQuantities[maxLotIdx]) {
            maxLotIdx = j;
          }
        }
        lotAmounts[maxLotIdx] += (landed - sumLot);
      } else {
        lotAmounts[0] = landed;
      }
    }

    lines.add(
      ReceiptCostLine(
        gross: grossList[i],
        tierDiscount: tierDiscountList[i],
        purchase: purchaseList[i],
        freight: freightList[i],
        discount: discountList[i],
        landed: landed,
        landedUnitCost: landedUnitCost,
        lotAmounts: lotAmounts,
      ),
    );
  }

  return ReceiptCostBreakdown(
    purchaseTotal: purchaseTotal,
    landedTotal: landedTotal,
    discountTooLarge: discountTooLarge,
    lines: lines,
  );
}

