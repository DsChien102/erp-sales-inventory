import '../ids/product_id.dart';
import '../readiness/product_readiness.dart';
import '../shared/product_status.dart';
import '../value_objects/barcode.dart';
import '../value_objects/product_name.dart';
import '../value_objects/sku.dart';
import 'events/product_created.dart';
import 'product_base_unit.dart';
import 'product_image.dart';
import 'rules/at_most_one_primary_image_rule.dart';
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
        hasBaseUnit: baseUnit != null,
        hasImages: normalizedImages.isNotEmpty,
      ),
      images: normalizedImages,
      baseUnit: baseUnit,
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
