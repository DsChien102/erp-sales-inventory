import '../return_exchange_order/ports/i_return_exchange_reference_port.dart';
import '../shared/pricing_snapshot_dto.dart';
import '../shared/product_snapshot_dto.dart';
import '../shared/product_unit_snapshot_dto.dart';
import '../shared/return_exchange_line_input.dart';
import '../shared/sales_blocker_dto.dart';

final class FakeReturnExchangeReferencePort implements IReturnExchangeReferencePort {
  FakeReturnExchangeReferencePort({
    ReturnExchangeReferenceDecision? decision,
    this.releaseError,
  }) : _decision = decision;

  factory FakeReturnExchangeReferencePort.ready({
    List<String> reservationIds = const <String>['res-1'],
    Map<String, PricingSnapshotDto> exchangePricingByProductUnitId =
        const <String, PricingSnapshotDto>{},
    Map<String, ProductSnapshotDto> exchangeProductsByProductUnitId =
        const <String, ProductSnapshotDto>{},
    Map<String, ProductUnitSnapshotDto> exchangeUnitsByProductUnitId =
        const <String, ProductUnitSnapshotDto>{},
    int? pricingSourceVersion = 1,
    int? inventorySourceVersion = 1,
  }) {
    return FakeReturnExchangeReferencePort(
      decision: ReturnExchangeReferenceDecision(
        blockers: const <SalesBlockerDto>[],
        exchangePricingByProductUnitId: exchangePricingByProductUnitId,
        exchangeProductsByProductUnitId: exchangeProductsByProductUnitId,
        exchangeUnitsByProductUnitId: exchangeUnitsByProductUnitId,
        pricingSourceVersion: pricingSourceVersion,
        inventorySourceVersion: inventorySourceVersion,
        reservationIds: reservationIds,
      ),
    );
  }

  factory FakeReturnExchangeReferencePort.blocked({
    required String code,
    String message = 'Blocked by reference providers.',
  }) {
    return FakeReturnExchangeReferencePort(
      decision: ReturnExchangeReferenceDecision(
        blockers: <SalesBlockerDto>[
          SalesBlockerDto(code: code, message: message),
        ],
        exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
        exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
        exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
        reservationIds: const <String>[],
      ),
    );
  }

  final ReturnExchangeReferenceDecision? _decision;
  Object? releaseError;

  int evaluateCalls = 0;
  int releaseCalls = 0;
  bool? lastReserveExchangeStock;
  String? lastSalesOrderId;
  List<ReturnExchangeLineInput>? lastLines;
  List<String>? lastReleasedReservationIds;
  String? lastReleaseIdempotencyKey;

  @override
  Future<ReturnExchangeReferenceDecision> evaluate({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required List<ReturnExchangeLineInput> lines,
    required bool reserveExchangeStock,
  }) async {
    evaluateCalls += 1;
    lastSalesOrderId = salesOrderId;
    lastLines = lines;
    lastReserveExchangeStock = reserveExchangeStock;
    return _decision ??
        ReturnExchangeReferenceDecision(
          blockers: const <SalesBlockerDto>[],
          exchangePricingByProductUnitId: const <String, PricingSnapshotDto>{},
          exchangeProductsByProductUnitId: const <String, ProductSnapshotDto>{},
          exchangeUnitsByProductUnitId: const <String, ProductUnitSnapshotDto>{},
          reservationIds: const <String>[],
        );
  }

  @override
  Future<void> releaseReservations({
    required String tenantId,
    required String returnExchangeId,
    required List<String> reservationIds,
    required String idempotencyKey,
  }) async {
    releaseCalls += 1;
    lastReleasedReservationIds = List<String>.unmodifiable(reservationIds);
    lastReleaseIdempotencyKey = idempotencyKey;
    if (releaseError != null) throw releaseError!;
  }
}
