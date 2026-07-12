import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../ids/product_id.dart';
import '../readiness/product_readiness.dart';
import '../readiness/readiness_blocker_code.dart';
import '../shared/product_status.dart';
import '../unit/product_base_unit.dart';
import 'barcode.dart';
import 'events/product_created.dart';
import 'events/product_deactivated.dart';
import 'events/product_deleted.dart';
import 'events/product_images_replaced.dart';
import 'events/product_profile_updated.dart';
import 'events/product_reactivated.dart';
import 'events/product_restored.dart';
import 'product_image.dart';
import 'product_name.dart';
import 'product_reference_id.dart';
import 'rules/at_most_one_primary_image_rule.dart';
import 'rules/product_must_be_active_rule.dart';
import 'rules/product_must_be_inactive_rule.dart';
import 'rules/product_must_be_soft_deleted_rule.dart';
import 'rules/product_must_not_be_soft_deleted_rule.dart';
import 'rules/product_name_required_rule.dart';
import 'sku.dart';

/// Product identity, profile, images, business status, and soft-delete.
final class Product extends Entity<ProductId> implements IAggregateRoot {
  Product._({
    required super.id,
    required this.tenantId,
    required this.referenceId,
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
    this.isSoftDeleted = false,
  });

  factory Product.create({
    required ProductId id,
    required TenantId tenantId,
    required ProductReferenceId referenceId,
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
      referenceId: referenceId,
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
      isSoftDeleted: false,
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
        referenceId: referenceId,
        productName: name.value,
      ),
    );
    return product;
  }

  factory Product.reconstitute({
    required ProductId id,
    required TenantId tenantId,
    required ProductReferenceId referenceId,
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
    bool isSoftDeleted = false,
  }) {
    return Product._(
      id: id,
      tenantId: tenantId,
      referenceId: referenceId,
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
      isSoftDeleted: isSoftDeleted,
    );
  }

  final TenantId tenantId;
  final ProductReferenceId referenceId;
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
  final bool isSoftDeleted;
  final String createdBy;
  final DateTime createdAt;
  final String updatedBy;
  final DateTime updatedAt;
  final int version;

  Product updateProfile({
    required ProductName name,
    required String actorId,
    ProductName? commercialName,
    Sku? sku,
    Barcode? barcode,
    String? description,
    String? note,
    DateTime? now,
  }) {
    checkRule(ProductMustNotBeSoftDeletedRule(isSoftDeleted));
    checkRule(ProductNameRequiredRule(name));

    final updatedAtTime = now ?? DateTime.now();
    final updated = Product._(
      id: id,
      tenantId: tenantId,
      referenceId: referenceId,
      name: name,
      commercialName: commercialName,
      sku: sku,
      barcode: barcode,
      description: _optionalText(description),
      note: _optionalText(note),
      status: status,
      readiness: readiness,
      images: images,
      baseUnit: baseUnit,
      isSoftDeleted: isSoftDeleted,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductProfileUpdated(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product replaceImages({
    required List<ProductImage> images,
    required String actorId,
    DateTime? now,
  }) {
    checkRule(ProductMustNotBeSoftDeletedRule(isSoftDeleted));
    final normalizedImages = _normalizeImages(images);
    checkRule(AtMostOnePrimaryImageRule(normalizedImages));

    final updatedAtTime = now ?? DateTime.now();
    final newReadiness = normalizedImages.isNotEmpty
        ? readiness.removeBlocker(ReadinessBlockerCode.missingImage)
        : readiness;
    final updated = _copy(
      images: normalizedImages,
      readiness: newReadiness,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductImagesReplaced(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product deactivate({
    required String actorId,
    DateTime? now,
  }) {
    checkRule(ProductMustNotBeSoftDeletedRule(isSoftDeleted));
    checkRule(ProductMustBeActiveRule(status));

    final updatedAtTime = now ?? DateTime.now();
    final updated = _copy(
      status: ProductStatus.inactive,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductDeactivated(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product reactivate({
    required String actorId,
    DateTime? now,
  }) {
    checkRule(ProductMustNotBeSoftDeletedRule(isSoftDeleted));
    checkRule(ProductMustBeInactiveRule(status));

    final updatedAtTime = now ?? DateTime.now();
    final updated = _copy(
      status: ProductStatus.active,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductReactivated(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product softDelete({
    required String actorId,
    DateTime? now,
  }) {
    checkRule(ProductMustNotBeSoftDeletedRule(isSoftDeleted));

    final updatedAtTime = now ?? DateTime.now();
    final updated = _copy(
      isSoftDeleted: true,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductDeleted(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product restore({
    required String actorId,
    DateTime? now,
  }) {
    checkRule(ProductMustBeSoftDeletedRule(isSoftDeleted));

    final updatedAtTime = now ?? DateTime.now();
    final updated = _copy(
      isSoftDeleted: false,
      updatedBy: actorId,
      updatedAt: updatedAtTime,
      version: version + 1,
    );
    updated.addDomainEvent(
      ProductRestored(productId: id, tenantId: tenantId),
    );
    return updated;
  }

  Product _copy({
    ProductName? name,
    ProductName? commercialName,
    Sku? sku,
    Barcode? barcode,
    String? description,
    String? note,
    ProductStatus? status,
    ProductReadiness? readiness,
    List<ProductImage>? images,
    ProductBaseUnit? baseUnit,
    bool? isSoftDeleted,
    String? updatedBy,
    DateTime? updatedAt,
    int? version,
  }) {
    return Product._(
      id: id,
      tenantId: tenantId,
      referenceId: referenceId,
      name: name ?? this.name,
      commercialName: commercialName ?? this.commercialName,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      description: description ?? this.description,
      note: note ?? this.note,
      status: status ?? this.status,
      readiness: readiness ?? this.readiness,
      images: images ?? this.images,
      baseUnit: baseUnit ?? this.baseUnit,
      isSoftDeleted: isSoftDeleted ?? this.isSoftDeleted,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
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
