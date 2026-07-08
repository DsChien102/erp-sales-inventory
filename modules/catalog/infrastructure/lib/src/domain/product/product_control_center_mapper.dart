import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import '../custom_fields/custom_field_rpc_mapper.dart';
import '../pricing/store_price_rule_rpc_mapper.dart';
import 'product_readiness_facts_mapper.dart';

abstract final class ProductControlCenterMapper {
  static ProductControlCenterReadModel fromJson(Map<String, dynamic> json) {
    final productId = json['product_id'] as String;
    final productName = json['name'] as String;

    final facts = ProductReadinessFacts(
      productId: productId,
      productName: productName,
      hasBaseUnit: json['has_base_unit'] as bool? ?? false,
      hasImages: json['has_images'] as bool? ?? false,
      hasStock: json['has_stock'] as bool? ?? false,
      hasBasePrice: json['has_base_price'] as bool? ?? false,
      hasPriceBand: json['has_price_band'] as bool? ?? false,
      hasRequiredCustomFields: json['has_required_custom_fields'] as bool? ?? true,
      stockMode: ProductReadinessFactsMapper.stockModeFromRpc(
        json['stock_mode'] as String?,
      ),
      basePriceMode: ProductReadinessFactsMapper.basePriceModeFromRpc(
        json['base_price_mode'] as String?,
      ),
    );

    final images = (json['images'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .toList(growable: false);

    final conversionUnits = (json['conversion_units'] as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductConversionUnitDto(
            name: map['name'] as String,
            conversionRate: (map['conversion_rate'] as num).toDouble(),
            isActive: map['is_active'] as bool? ?? true,
          );
        })
        .toList(growable: false);

    final history = (json['change_history_preview'] as List<dynamic>? ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return ProductChangeHistoryEntryDto(
            id: map['id'] as String,
            occurredAt: DateTime.parse(map['occurred_at'] as String),
            actorDisplayName: map['actor_display_name'] as String,
            changeType: map['change_type'] as String,
            summary: map['summary'] as String,
            valueBefore: map['value_before'] as String?,
            valueAfter: map['value_after'] as String?,
          );
        })
        .toList(growable: false);

    return ProductControlCenterReadModel(
      productId: productId,
      name: productName,
      tradeName: json['trade_name'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      businessStatus: _businessStatusFromRpc(
        json['business_status'] as String?,
      ),
      isSoftDeleted: json['is_soft_deleted'] as bool? ?? false,
      primaryImageUrl: json['primary_image_url'] as String?,
      images: images,
      baseUnitName: json['base_unit_name'] as String?,
      conversionUnits: conversionUnits,
      facts: facts,
      stockQuantity: _toInt(json['stock_qty']),
      stockVersion: _toInt(json['stock_version']),
      basePriceAmount: _toDouble(json['base_price_amount']),
      basePriceCurrency: json['base_price_currency'] as String? ?? 'VND',
      listPrice: _toDouble(json['list_price']),
      floorPrice: _toDouble(json['floor_price']),
      priceBandSourceType: StorePriceRuleRpcMapper.sourceTypeFromRpc(
        json['price_band_source_type'] as String?,
      ),
      storePriceRuleName: json['store_price_rule_name'] as String?,
      isCustomOverride: json['is_custom_override'] as bool? ?? false,
      customFieldGroupCards: _customFieldGroupCardsFromJson(
        json['custom_field_group_cards'],
      ),
      changeHistoryPreview: history,
    );
  }

  static List<CustomFieldGroupCardDto> _customFieldGroupCardsFromJson(
    Object? value,
  ) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => CustomFieldRpcMapper.customFieldGroupCardFromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList(growable: false);
  }

  static ProductStatus _businessStatusFromRpc(String? value) {
    return switch (value) {
      'inactive' => ProductStatus.inactive,
      _ => ProductStatus.active,
    };
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }
}
