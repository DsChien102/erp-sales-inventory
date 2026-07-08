import '../pricing/base_price_mode.dart';
import '../stock/stock_mode.dart';
import 'product_readiness.dart';
import 'product_readiness_facts.dart';
import 'readiness_blocker.dart';
import 'readiness_blocker_code.dart';
import 'readiness_status.dart';

/// Computes [ProductReadiness] from operational facts and tenant modes.
abstract final class ProductReadinessEvaluator {
  static ProductReadiness compute(ProductReadinessFacts facts) {
    final blockers = <ReadinessBlocker>[];

    if (!facts.hasBaseUnit) {
      blockers.add(ReadinessBlocker.missingBaseUnit());
    }
    if (!facts.hasImages) {
      blockers.add(ReadinessBlocker.missingImage());
    }

    _appendStockBlockers(blockers, facts);
    _appendBasePriceBlockers(blockers, facts);

    if (!facts.hasPriceBand) {
      blockers.add(ReadinessBlocker.missingPriceBand());
    }
    if (!facts.hasRequiredCustomFields) {
      blockers.add(ReadinessBlocker.missingRequiredCustomFields());
    }

    final requiredBlockers = blockers
        .where((blocker) => blocker.code != ReadinessBlockerCode.missingImage)
        .toList(growable: false);

    return ProductReadiness(
      status: requiredBlockers.isEmpty
          ? ReadinessStatus.readyToSell
          : ReadinessStatus.incomplete,
      blockers: List.unmodifiable(blockers),
    );
  }

  static void _appendStockBlockers(
    List<ReadinessBlocker> blockers,
    ProductReadinessFacts facts,
  ) {
    if (facts.stockMode == StockMode.advanced) {
      if (!facts.hasStock) {
        blockers.add(ReadinessBlocker.pendingStockFromInventory());
      }
      return;
    }
    if (!facts.hasStock) {
      blockers.add(ReadinessBlocker.missingStock());
    }
  }

  static void _appendBasePriceBlockers(
    List<ReadinessBlocker> blockers,
    ProductReadinessFacts facts,
  ) {
    if (facts.basePriceMode == BasePriceMode.costingModule) {
      if (!facts.hasBasePrice) {
        blockers.add(ReadinessBlocker.pendingBasePriceFromCosting());
      }
      return;
    }
    if (!facts.hasBasePrice) {
      blockers.add(ReadinessBlocker.missingPrice());
    }
  }
}
