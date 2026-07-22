import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_presentation/src/bloc/product_guided_create_state.dart';
import 'package:vet45_catalog_presentation/src/mappers/guided_price_band_submission_resolver.dart';

void main() {
  group('GuidedPriceBandSubmissionResolver', () {
    test('defaults an untouched price step to the store rule', () {
      const state = ProductGuidedCreateState(name: 'Thuốc A');

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandReady>());
      final ready = result as GuidedPriceBandReady;
      expect(ready.submission.sourceType, PriceBandSourceType.ruleBased);
      expect(ready.submission.useStorePriceRule, isTrue);
      expect(ready.submission.listBeforeVat, isNull);
      expect(ready.submission.floorBeforeVat, isNull);
      expect(ready.submission.listMarkupRatio, isNull);
      expect(ready.submission.floorMarkupRatio, isNull);
    });

    test('resolves a complete custom configuration without requiring Next', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseUnit: 'Lọ',
        baseCost: '50000',
        pricingMethod: 'customAuto',
        customAutoMarkup: '30',
        customAutoFloorMarkup: '10',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandReady>());
      final submission = (result as GuidedPriceBandReady).submission;
      expect(submission.sourceType, PriceBandSourceType.customConfig);
      expect(submission.useStorePriceRule, isFalse);
      expect(submission.listBeforeVat, 65000);
      expect(submission.floorBeforeVat, 55000);
      expect(submission.listMarkupRatio, 0.3);
      expect(submission.floorMarkupRatio, 0.1);
    });

    test('resolves complete manual prices and keeps floor optional', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseUnit: 'Lọ',
        pricingMethod: 'manual',
        manualListPrice: '70,000',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandReady>());
      final submission = (result as GuidedPriceBandReady).submission;
      expect(submission.sourceType, PriceBandSourceType.manual);
      expect(submission.useStorePriceRule, isFalse);
      expect(submission.listBeforeVat, 70000);
      expect(submission.floorBeforeVat, isNull);
    });

    test('targets base unit step when a custom configuration has no unit', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseCost: '50000',
        pricingMethod: 'customAuto',
        customAutoMarkup: '30',
        customAutoFloorMarkup: '10',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandInvalid>());
      expect((result as GuidedPriceBandInvalid).targetStepIndex, 2);
    });

    test('keeps custom configuration pending when base price is missing', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseUnit: 'Lọ',
        pricingMethod: 'customAuto',
        customAutoMarkup: '30',
        customAutoFloorMarkup: '10',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandReady>());
      final submission = (result as GuidedPriceBandReady).submission;
      expect(submission.sourceType, PriceBandSourceType.customConfig);
      expect(submission.listBeforeVat, 0);
      expect(submission.floorBeforeVat, 0);
      expect(submission.listMarkupRatio, 0.3);
      expect(submission.floorMarkupRatio, 0.1);
    });

    test('rejects incomplete custom ratios at the price band step', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseUnit: 'Lọ',
        baseCost: '50000',
        pricingMethod: 'customAuto',
        customAutoMarkup: '30',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandInvalid>());
      expect((result as GuidedPriceBandInvalid).targetStepIndex, 5);
    });

    test('rejects manual floor greater than list at the price band step', () {
      const state = ProductGuidedCreateState(
        name: 'Thuốc A',
        baseUnit: 'Lọ',
        pricingMethod: 'manual',
        manualListPrice: '50,000',
        manualFloorPrice: '60,000',
      );

      final result = GuidedPriceBandSubmissionResolver.resolve(state);

      expect(result, isA<GuidedPriceBandInvalid>());
      final invalid = result as GuidedPriceBandInvalid;
      expect(invalid.targetStepIndex, 5);
      expect(invalid.manualPriceError, 'Giá sàn phải ≤ giá niêm yết');
    });
  });
}
