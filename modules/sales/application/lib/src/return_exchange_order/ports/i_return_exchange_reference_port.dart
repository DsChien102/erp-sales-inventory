import '../../shared/pricing_snapshot_dto.dart';
import '../../shared/product_snapshot_dto.dart';
import '../../shared/product_unit_snapshot_dto.dart';
import '../../shared/return_exchange_line_input.dart';
import '../../shared/sales_blocker_dto.dart';

final class ReturnExchangeReferenceDecision {
  ReturnExchangeReferenceDecision({
    required List<SalesBlockerDto> blockers,
    required Map<String, PricingSnapshotDto> exchangePricingByProductUnitId,
    required Map<String, ProductSnapshotDto> exchangeProductsByProductUnitId,
    required Map<String, ProductUnitSnapshotDto> exchangeUnitsByProductUnitId,
    this.pricingSourceVersion,
    this.inventorySourceVersion,
    required List<String> reservationIds,
  }) : blockers = List.unmodifiable(blockers),
       exchangePricingByProductUnitId = Map.unmodifiable(
         exchangePricingByProductUnitId,
       ),
       exchangeProductsByProductUnitId = Map.unmodifiable(
         exchangeProductsByProductUnitId,
       ),
       exchangeUnitsByProductUnitId = Map.unmodifiable(
         exchangeUnitsByProductUnitId,
       ),
       reservationIds = List.unmodifiable(reservationIds);

  final List<SalesBlockerDto> blockers;
  final Map<String, PricingSnapshotDto> exchangePricingByProductUnitId;
  final Map<String, ProductSnapshotDto> exchangeProductsByProductUnitId;
  final Map<String, ProductUnitSnapshotDto> exchangeUnitsByProductUnitId;
  final int? pricingSourceVersion;
  final int? inventorySourceVersion;
  final List<String> reservationIds;

  bool get allowed => blockers.isEmpty;
}

abstract interface class IReturnExchangeReferencePort {
  Future<ReturnExchangeReferenceDecision> evaluate({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required List<ReturnExchangeLineInput> lines,
    required bool reserveExchangeStock,
  });

  Future<void> releaseReservations({
    required String tenantId,
    required String returnExchangeId,
    required List<String> reservationIds,
    required String idempotencyKey,
  });
}
