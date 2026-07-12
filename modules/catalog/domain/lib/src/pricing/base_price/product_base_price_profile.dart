import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../../exceptions/not_manual_base_price_mode_exception.dart';
import '../../ids/product_id.dart';
import '../base_price.dart';
import '../base_price_mode.dart';
import 'events/product_base_price_updated.dart';

/// Manual / costing-module base price profile (1:1 with Product).
final class ProductBasePriceProfile extends Entity<ProductId> implements IAggregateRoot {
  ProductBasePriceProfile._({
    required super.id,
    required this.tenantId,
    required this.mode,
    this.basePrice,
  });

  final TenantId tenantId;
  final BasePriceMode mode;
  final BasePrice? basePrice;

  /// Snapshot factory for Phase 1–2 gateway passthrough.
  factory ProductBasePriceProfile.manual({BasePrice? basePrice}) {
    return ProductBasePriceProfile._(
      id: const ProductId('_snapshot'),
      tenantId: const TenantId('_snapshot'),
      mode: BasePriceMode.manual,
      basePrice: basePrice,
    );
  }

  factory ProductBasePriceProfile.costingModule() {
    return ProductBasePriceProfile._(
      id: const ProductId('_snapshot'),
      tenantId: const TenantId('_snapshot'),
      mode: BasePriceMode.costingModule,
      basePrice: null,
    );
  }

  factory ProductBasePriceProfile.reconstitute({
    required ProductId productId,
    required TenantId tenantId,
    required BasePriceMode mode,
    BasePrice? basePrice,
  }) {
    return ProductBasePriceProfile._(
      id: productId,
      tenantId: tenantId,
      mode: mode,
      basePrice: basePrice,
    );
  }

  ProductBasePriceProfile setManual({
    required double amount,
    required String actorId,
    String currency = 'VND',
    DateTime? now,
  }) {
    if (mode.isCostingModule) {
      throw NotManualBasePriceModeException();
    }

    final price = BasePrice(amount: amount, currency: currency);
    final updated = ProductBasePriceProfile._(
      id: id,
      tenantId: tenantId,
      mode: BasePriceMode.manual,
      basePrice: price,
    );
    updated.addDomainEvent(
      ProductBasePriceUpdated(
        productId: id,
        tenantId: tenantId,
        basePrice: amount,
      ),
    );
    return updated;
  }

  ProductBasePriceProfile withBasePrice(BasePrice price) {
    return ProductBasePriceProfile._(
      id: id,
      tenantId: tenantId,
      mode: mode,
      basePrice: price,
    );
  }
}
