import '../ids/product_id.dart';
import '../readiness/product_readiness.dart';
import '../shared/product_status.dart';
import '../value_objects/barcode.dart';
import '../value_objects/product_name.dart';
import '../value_objects/sku.dart';
import 'events/product_created.dart';
import 'product_base_unit.dart';
import 'product_image.dart';
import '../exceptions/floor_price_greater_than_list_price_exception.dart';
import '../exceptions/missing_base_unit_exception.dart';
import '../exceptions/not_basic_stock_mode_exception.dart';
import '../exceptions/not_manual_base_price_mode_exception.dart';
import '../pricing/base_price.dart';
import '../pricing/base_price_mode.dart';
import '../pricing/floor_price.dart';
import '../pricing/list_price.dart';
import '../pricing/product_base_price_profile.dart';
import '../pricing/product_unit_price_band.dart';
import '../readiness/readiness_blocker_code.dart';
import '../stock/product_stock_profile.dart';
import '../stock/stock_mode.dart';
import 'events/product_base_price_updated.dart';
import 'events/product_price_band_changed.dart';
import 'events/product_stock_adjusted.dart';
import 'rules/at_most_one_primary_image_rule.dart';
import 'rules/base_unit_required_for_stock_rule.dart';
import 'rules/floor_price_not_greater_than_list_price_rule.dart';
import 'rules/product_name_required_rule.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class Product extends Entity<ProductId> implements IAggregateRoot {
  Product._({
    required super.id,
    required this.tenantId,
    required this.name,
    required this.status,
    required this.readiness,
    required this.images,
    required this.createdBy,
    required this.createdAt,
    required this.updatedBy,
    required this.updatedAt,
    required this.version,
    this.commercialName,
    this.sku,
    this.barcode,
    this.description,
    this.note,
    this.baseUnit,
    this.stockProfile,
    this.basePriceProfile,
    this.priceBands = const [],
  });

  factory Product.create({
    required ProductId id,
    required TenantId tenantId,
    required ProductName name,
    required String actorId,
    DateTime? now,
    ProductName? commercialName,
    Sku? sku,
    Barcode? barcode,
    String? description,
    String? note,
    List<ProductImage> images = const [],
    ProductBaseUnit? baseUnit,
  }) {
    final createdAt = now ?? DateTime.now();
    final normalizedImages = _normalizeImages(images);

    final product = Product._(
      id: id,
      tenantId: tenantId,
      name: name,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: _optionalText(description),
      note: _optionalText(note),
      status: ProductStatus.active,
      readiness: ProductReadiness.seedFromCreate(
        productId: id.value,
        productName: name.value,
        hasBaseUnit: baseUnit != null,
        hasImages: normalizedImages.isNotEmpty,
      ),
      images: normalizedImages,
      baseUnit: baseUnit,
      stockProfile: null,
      basePriceProfile: null,
      priceBands: const [],
      createdBy: actorId,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: createdAt,
      version: 1,
    );

    product._validateCreateInvariants();
    product.addDomainEvent(
      ProductCreated(
        productId: id,
        tenantId: tenantId,
        productName: name.value,
      ),
    );
    return product;
  }

  factory Product.reconstitute({
    required ProductId id,
    required TenantId tenantId,
    required ProductName name,
    required ProductStatus status,
    required ProductReadiness readiness,
    required List<ProductImage> images,
    required String createdBy,
    required DateTime createdAt,
    required String updatedBy,
    required DateTime updatedAt,
    required int version,
    ProductName? commercialName,
    Sku? sku,
    Barcode? barcode,
    String? description,
    String? note,
    ProductBaseUnit? baseUnit,
    ProductStockProfile? stockProfile,
    ProductBasePriceProfile? basePriceProfile,
    List<ProductUnitPriceBand> priceBands = const [],
  }) {
    return Product._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      readiness: readiness,
      images: images,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy,
      updatedAt: updatedAt,
      version: version,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      baseUnit: baseUnit,
      stockProfile: stockProfile,
      basePriceProfile: basePriceProfile,
      priceBands: priceBands,
    );
  }

  final TenantId tenantId;
  final ProductName name;
  final ProductName? commercialName;
  final Sku? sku;
  final Barcode? barcode;
  final String? description;
  final String? note;
  final ProductStatus status;
  final ProductReadiness readiness;
  final List<ProductImage> images;
  final ProductBaseUnit? baseUnit;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;
  final ProductStockProfile? stockProfile;
  final ProductBasePriceProfile? basePriceProfile;
  final List<ProductUnitPriceBand> priceBands;

  Product setInitialStock({
    required double quantity,
    required StockMode mode,
    required String actorId,
    DateTime? now,
  }) {
    final rule = BaseUnitRequiredForStockRule(baseUnit);
    if (rule.isBroken()) {
      throw MissingBaseUnitException(rule.message);
    }
    if (mode.isAdvanced) {
      throw NotBasicStockModeException();
    }

    final updatedAtTime = now ?? DateTime.now();
    final newProfile = ProductStockProfile.basic(initialStock: quantity);
    final newReadiness = readiness.removeBlocker(ReadinessBlockerCode.missingStock);

    final updatedProduct = Product._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      readiness: newReadiness,
      images: images,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      baseUnit: baseUnit,
      stockProfile: newProfile,
      basePriceProfile: basePriceProfile,
      priceBands: priceBands,
    );

    for (final event in (domainEvents ?? const <IDomainEvent>[])) {
      updatedProduct.addDomainEvent(event);
    }
    updatedProduct.addDomainEvent(
      ProductStockAdjusted(
        productId: id,
        tenantId: tenantId,
        quantity: quantity,
      ),
    );

    return updatedProduct;
  }

  Product setManualBasePrice({
    required double basePrice,
    required BasePriceMode mode,
    required String actorId,
    DateTime? now,
  }) {
    if (mode.isCostingModule) {
      throw NotManualBasePriceModeException();
    }

    final updatedAtTime = now ?? DateTime.now();
    final newProfile = ProductBasePriceProfile.manual(
      basePrice: BasePrice(amount: basePrice),
    );
    final newReadiness = readiness.removeBlocker(ReadinessBlockerCode.missingPrice);

    final updatedProduct = Product._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      readiness: newReadiness,
      images: images,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      baseUnit: baseUnit,
      stockProfile: stockProfile,
      basePriceProfile: newProfile,
      priceBands: priceBands,
    );

    for (final event in (domainEvents ?? const <IDomainEvent>[])) {
      updatedProduct.addDomainEvent(event);
    }
    updatedProduct.addDomainEvent(
      ProductBasePriceUpdated(
        productId: id,
        tenantId: tenantId,
        basePrice: basePrice,
      ),
    );

    return updatedProduct;
  }

  Product setInitialPriceBand({
    required String productUnitId,
    required double listPrice,
    required double floorPrice,
    required String actorId,
    DateTime? now,
  }) {
    final listPriceVo = ListPrice(amount: listPrice);
    final floorPriceVo = FloorPrice(amount: floorPrice);

    final rule = FloorPriceNotGreaterThanListPriceRule(
      floorPrice: floorPriceVo,
      listPrice: listPriceVo,
    );
    if (rule.isBroken()) {
      throw FloorPriceGreaterThanListPriceException(rule.message);
    }

    final updatedAtTime = now ?? DateTime.now();
    final newBand = ProductUnitPriceBand(
      id: '${id.value}_$productUnitId',
      tenantId: tenantId.value,
      productId: id.value,
      productUnitId: productUnitId,
      listPrice: listPriceVo,
      floorPrice: floorPriceVo,
    );

    final updatedBands = priceBands
        .where((b) => b.productUnitId != productUnitId)
        .toList()
      ..add(newBand);
    final newReadiness = readiness.removeBlocker(ReadinessBlockerCode.missingPriceBand);

    final updatedProduct = Product._(
      id: id,
      tenantId: tenantId,
      name: name,
      status: status,
      readiness: newReadiness,
      images: images,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: description,
      note: note,
      baseUnit: baseUnit,
      stockProfile: stockProfile,
      basePriceProfile: basePriceProfile,
      priceBands: List.unmodifiable(updatedBands),
    );

    for (final event in (domainEvents ?? const <IDomainEvent>[])) {
      updatedProduct.addDomainEvent(event);
    }
    updatedProduct.addDomainEvent(
      ProductPriceBandChanged(
        productId: id,
        tenantId: tenantId,
        productUnitId: productUnitId,
        listPrice: listPrice,
        floorPrice: floorPrice,
      ),
    );

    return updatedProduct;
  }

  void _validateCreateInvariants() {
    checkRule(ProductNameRequiredRule(name));
    checkRule(AtMostOnePrimaryImageRule(images));
  }

  static List<ProductImage> _normalizeImages(List<ProductImage> images) {
    if (images.isEmpty) {
      return const [];
    }

    final hasPrimary = images.any((image) => image.isPrimary);
    if (hasPrimary) {
      return List.unmodifiable(images);
    }

    return List.unmodifiable([
      ProductImage(
        storageKey: images.first.storageKey,
        url: images.first.url,
        isPrimary: true,
        sortOrder: images.first.sortOrder,
      ),
      ...images.skip(1),
    ]);
  }

  static String? _optionalText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
