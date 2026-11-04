import '../../data/models.dart';
import '../../logic/product_guided_create_state.dart';
import '../../logic/store_price_suggestion.dart';
import '../utils/catalog_currency_formatters.dart';

final class GuidedPriceBandSubmission {
  const GuidedPriceBandSubmission({
    required this.sourceType,
    required this.useStorePriceRule,
    this.listBeforeVat,
    this.floorBeforeVat,
    this.listMarkupRatio,
    this.floorMarkupRatio,
  });

  final PriceBandSourceType sourceType;
  final bool useStorePriceRule;
  /// Absolute list amount from UI (treated as after-VAT). Wired to
  /// [SetInitialPriceBandCommand.listBeforeVat]; BE mirrors after ← before.
  final int? listBeforeVat;
  /// Absolute floor amount from UI (treated as after-VAT). Wired to
  /// [SetInitialPriceBandCommand.floorBeforeVat]; BE mirrors after ← before.
  final int? floorBeforeVat;
  final double? listMarkupRatio;
  final double? floorMarkupRatio;
}

sealed class GuidedPriceBandResolution {
  const GuidedPriceBandResolution();
}

final class GuidedPriceBandReady extends GuidedPriceBandResolution {
  const GuidedPriceBandReady(this.submission);

  final GuidedPriceBandSubmission submission;
}

final class GuidedPriceBandInvalid extends GuidedPriceBandResolution {
  const GuidedPriceBandInvalid({
    required this.message,
    required this.targetStepIndex,
    this.manualPriceError,
  });

  final String message;
  final int targetStepIndex;
  final String? manualPriceError;
}

abstract final class GuidedPriceBandSubmissionResolver {
  static GuidedPriceBandResolution resolve(ProductGuidedCreateState state) {
    return switch (state.pricingMethod) {
      'storeRule' => const GuidedPriceBandReady(
        GuidedPriceBandSubmission(
          sourceType: PriceBandSourceType.ruleBased,
          useStorePriceRule: true,
        ),
      ),
      'customAuto' || 'auto' => _resolveCustomConfig(state),
      'manual' => _resolveManual(state),
      _ => const GuidedPriceBandInvalid(
        message: 'Cách tính giá không hợp lệ.',
        targetStepIndex: 5,
      ),
    };
  }

  static GuidedPriceBandResolution _resolveCustomConfig(
    ProductGuidedCreateState state,
  ) {
    if (state.baseUnit.trim().isEmpty) {
      return const GuidedPriceBandInvalid(
        message: 'Cần thiết lập đơn vị cơ sở trước khi cấu hình giá.',
        targetStepIndex: 2,
      );
    }

    final baseCost = parseCatalogCurrencyAmount(state.baseCost);
    final listPercent = state.parsedCustomAutoMarkupPercent;
    final floorPercent = state.parsedCustomAutoFloorMarkupPercent;
    if (listPercent == null || floorPercent == null) {
      return const GuidedPriceBandInvalid(
        message: 'Vui lòng nhập tỷ lệ lãi cơ sở và giá sàn hợp lệ.',
        targetStepIndex: 5,
      );
    }
    if (floorPercent > listPercent) {
      return const GuidedPriceBandInvalid(
        message: 'Tỷ lệ giá sàn không được lớn hơn tỷ lệ lãi cơ sở.',
        targetStepIndex: 5,
      );
    }

    final listRatio = listPercent / 100;
    final floorRatio = floorPercent / 100;
    final suggested = baseCost == null
        ? null
        : StorePriceSuggestionCalculator.suggest(
            basePrice: baseCost.toDouble(),
            listMarkupRatio: listRatio,
            floorMarkupRatio: floorRatio,
          );
    return GuidedPriceBandReady(
      GuidedPriceBandSubmission(
        sourceType: PriceBandSourceType.customConfig,
        useStorePriceRule: false,
        listBeforeVat: suggested?.listBeforeVat ?? 0,
        floorBeforeVat: suggested?.floorBeforeVat ?? 0,
        listMarkupRatio: listRatio,
        floorMarkupRatio: floorRatio,
      ),
    );
  }

  static GuidedPriceBandResolution _resolveManual(
    ProductGuidedCreateState state,
  ) {
    if (state.baseUnit.trim().isEmpty) {
      return const GuidedPriceBandInvalid(
        message: 'Cần thiết lập đơn vị cơ sở trước khi nhập giá thủ công.',
        targetStepIndex: 2,
      );
    }

    final listPrice = parseCatalogCurrencyAmount(state.manualListPrice);
    if (listPrice == null) {
      return const GuidedPriceBandInvalid(
        message: 'Giá niêm yết là bắt buộc.',
        targetStepIndex: 5,
        manualPriceError: 'Nhập giá niêm yết',
      );
    }

    final floorRaw = state.manualFloorPrice.trim();
    final floorPrice = floorRaw.isEmpty ? null : parseCatalogCurrencyAmount(floorRaw);
    if (floorRaw.isNotEmpty && floorPrice == null) {
      return const GuidedPriceBandInvalid(
        message: 'Giá sàn không hợp lệ.',
        targetStepIndex: 5,
        manualPriceError: 'Nhập giá sàn hợp lệ',
      );
    }
    if (floorPrice != null && floorPrice > listPrice) {
      return const GuidedPriceBandInvalid(
        message: 'Giá sàn không được lớn hơn giá niêm yết.',
        targetStepIndex: 5,
        manualPriceError: 'Giá sàn phải ≤ giá niêm yết',
      );
    }

    return GuidedPriceBandReady(
      GuidedPriceBandSubmission(
        sourceType: PriceBandSourceType.manual,
        useStorePriceRule: false,
        listBeforeVat: listPrice,
        floorBeforeVat: floorPrice,
      ),
    );
  }
}
