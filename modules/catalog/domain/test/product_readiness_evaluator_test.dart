import 'package:test/test.dart';
import 'package:vet45_catalog_domain/domain.dart';

void main() {
  group('ProductReadinessEvaluator', () {
    test('scn_e02_u03_fr01_01 many blockers for minimal create facts', () {
      final readiness = ProductReadinessEvaluator.compute(
        ProductReadinessFacts.forCreate(
          productId: 'product-1',
          productName: 'Thuốc A',
          hasBaseUnit: false,
          hasImages: false,
        ),
      );

      expect(readiness.status, ReadinessStatus.incomplete);
      expect(
        readiness.blockers.map((blocker) => blocker.code),
        containsAll([
          ReadinessBlockerCode.missingBaseUnit,
          ReadinessBlockerCode.missingImage,
          ReadinessBlockerCode.missingStock,
          ReadinessBlockerCode.missingPrice,
          ReadinessBlockerCode.missingPriceBand,
        ]),
      );
    });

    test('scn_e02_u03_fr01_02 ready to sell when all required facts present', () {
      final readiness = ProductReadinessEvaluator.compute(
        const ProductReadinessFacts(
          productId: 'product-2',
          productName: 'Thuốc B',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: true,
          hasRequiredCustomFields: true,
        ),
      );

      expect(readiness.status, ReadinessStatus.readyToSell);
      expect(readiness.blockers, isEmpty);
    });

    test('scn_e02_u03_fr01_03 advanced stock pending external blocker', () {
      final readiness = ProductReadinessEvaluator.compute(
        const ProductReadinessFacts(
          productId: 'product-3',
          productName: 'Thuốc C',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: false,
          hasBasePrice: false,
          hasPriceBand: false,
          hasRequiredCustomFields: true,
          stockMode: StockMode.advanced,
        ),
      );

      expect(
        readiness.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.pendingStockFromInventory),
      );
      expect(
        readiness.blockers.map((blocker) => blocker.code),
        isNot(contains(ReadinessBlockerCode.missingStock)),
      );
    });

    test('scn_e02_u03_fr01_04 costing base price pending external blocker', () {
      final readiness = ProductReadinessEvaluator.compute(
        const ProductReadinessFacts(
          productId: 'product-4',
          productName: 'Thuốc D',
          hasBaseUnit: true,
          hasImages: true,
          hasStock: false,
          hasBasePrice: false,
          hasPriceBand: false,
          hasRequiredCustomFields: true,
          basePriceMode: BasePriceMode.costingModule,
        ),
      );

      expect(
        readiness.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.pendingBasePriceFromCosting),
      );
      expect(
        readiness.blockers.map((blocker) => blocker.code),
        isNot(contains(ReadinessBlockerCode.missingPrice)),
      );
    });

    test('missing image does not block ready to sell', () {
      final readiness = ProductReadinessEvaluator.compute(
        const ProductReadinessFacts(
          productId: 'product-5',
          productName: 'Thuốc E',
          hasBaseUnit: true,
          hasImages: false,
          hasStock: true,
          hasBasePrice: true,
          hasPriceBand: true,
          hasRequiredCustomFields: true,
        ),
      );

      expect(readiness.status, ReadinessStatus.readyToSell);
      expect(
        readiness.blockers.map((blocker) => blocker.code),
        contains(ReadinessBlockerCode.missingImage),
      );
    });
  });
}
