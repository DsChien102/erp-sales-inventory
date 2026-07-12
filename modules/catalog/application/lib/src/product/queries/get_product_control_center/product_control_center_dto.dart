import 'package:vet45_catalog_application/src/product_readiness/shared/contextual_action_dto.dart';
import 'package:vet45_catalog_application/src/product_readiness/shared/readiness_checklist_item_dto.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'custom_field_group_card_dto.dart';
import 'product_base_price_card_dto.dart';
import 'package:vet45_catalog_application/src/product_change_history/shared/product_change_history_entry_dto.dart';
import 'product_price_band_card_dto.dart';
import 'product_profile_summary_dto.dart';
import 'product_stock_card_dto.dart';
import 'product_units_card_dto.dart';

/// Aggregate read model for Product Control Center (EPIC-01/US-02).
final class ProductControlCenterDto {
  const ProductControlCenterDto({
    required this.profile,
    required this.units,
    required this.stock,
    required this.basePrice,
    required this.priceBand,
    this.customFieldGroupCards = const [],
    required this.readinessSummary,
    this.checklist = const [],
    this.contextualActions = const [],
    this.changeHistoryPreview = const [],
    this.primaryActionId,
  });

  final ProductProfileSummaryDto profile;
  final ProductUnitsCardDto units;
  final ProductStockCardDto stock;
  final ProductBasePriceCardDto basePrice;
  final ProductPriceBandCardDto priceBand;
  final List<CustomFieldGroupCardDto> customFieldGroupCards;
  final ReadinessSummaryDto readinessSummary;

  /// Full checklist UI is **pending** (EPIC-01/US-02/FR-04) — empty in Foundation.
  final List<ReadinessChecklistItemDto> checklist;
  final List<ContextualActionDto> contextualActions;
  final List<ProductChangeHistoryEntryDto> changeHistoryPreview;
  final String? primaryActionId;
}
