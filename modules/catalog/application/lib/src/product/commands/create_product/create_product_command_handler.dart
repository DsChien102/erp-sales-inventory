import 'package:uuid/uuid.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'package:vet45_catalog_application/src/exceptions/duplicate_reference_id_exception.dart';
import 'package:vet45_catalog_application/src/ports/i_product_command_gateway.dart';
import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'create_product_command.dart';
import 'create_product_result.dart';
import 'package:vet45_catalog_application/src/product/shared/product_image_input.dart';

@CommandHandlerFor(CreateProductCommand)
final class CreateProductCommandHandler
    implements ICommandHandler<CreateProductCommand, CreateProductResult> {
  CreateProductCommandHandler({
    required IProductCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IProductCommandGateway _commandGateway;

  @override
  Future<CreateProductResult> handle(CreateProductCommand command) async {
    final explicitReferenceId = _optionalReferenceId(command.referenceId);
    const maxAttempts = 3;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final productId = ProductId(const Uuid().v4());
      final referenceId = explicitReferenceId ?? ProductReferenceId.fromProductId(productId);

      final product = Product.create(
        id: productId,
        tenantId: TenantId(command.tenantId),
        referenceId: referenceId,
        name: ProductName(command.productName),
        actorId: command.actorId,
        commercialName: _optionalName(command.commercialName),
        sku: _optionalSku(command.sku),
        barcode: _optionalBarcode(command.barcode),
        description: command.description,
        note: command.note,
        images: command.images.map(_toImage).toList(growable: false),
        baseUnit: _optionalBaseUnit(command.baseUnitName),
      );

      try {
        final registeredProductId = await _commandGateway.create(
          product: product,
          idempotencyKey: command.id,
        );

        return CreateProductResult(
          productId: registeredProductId,
          readinessSummary: ReadinessSummaryDto.fromDomain(product.readiness),
        );
      } on DuplicateReferenceIdException {
        if (explicitReferenceId != null) {
          rethrow;
        }
      }
    }

    throw ApplicationException(
      'Unable to generate a unique product reference id.',
    );
  }

  ProductReferenceId? _optionalReferenceId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return ProductReferenceId(trimmed);
  }

  ProductImage _toImage(ProductImageInput input) {
    return ProductImage(
      storageKey: input.storageKey,
      slotId: input.slotId,
      url: input.url,
      isPrimary: input.isPrimary,
      sortOrder: input.sortOrder,
    );
  }

  ProductName? _optionalName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return ProductName(trimmed);
  }

  Sku? _optionalSku(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return Sku(trimmed);
  }

  Barcode? _optionalBarcode(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return Barcode(trimmed);
  }

  ProductBaseUnit? _optionalBaseUnit(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return ProductBaseUnit(trimmed);
  }
}
