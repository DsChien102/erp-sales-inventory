import 'dart:async';

import 'package:erp/features/sales/data/models/return_exchange_requests.dart';
import 'package:erp/features/sales/data/return_exchange_repository.dart';
import 'package:vet45_sales_application/application.dart';

/// Fake ReturnExchangeRepository dùng cho unit test cubit và view test.
final class FakeReturnExchangeRepository implements ReturnExchangeRepository {
  ReturnExchangePrecheckDto? precheckResult;
  final precheckResults = <ReturnExchangePrecheckDto>[];
  Object? precheckError;
  final precheckCalls = <({String salesOrderId, int? expectedSourceVersion})>[];

  ReturnableOrderLinesDto? returnableResult;
  final returnableResults = <ReturnableOrderLinesDto>[];
  Object? returnableError;
  final returnableCalls = <String>[];

  ReturnExchangePricingPreviewDto? previewResult;
  final previewResults = <ReturnExchangePricingPreviewDto>[];
  Object? previewError;
  final previewCalls = <({String salesOrderId, List<ReturnExchangePricingLineInput> lines})>[];

  ReturnExchangeDetailDto? detailResult;
  final detailResults = <ReturnExchangeDetailDto>[];
  Object? detailError;
  final detailCalls = <String>[];

  /// Nếu đặt, [getDetail] chờ cổng này (sau khi ghi lời gọi, trước khi ném lỗi / trả kết quả).
  Completer<void>? detailGate;

  ReturnExchangeDraftDto? startResult;
  final startResults = <ReturnExchangeDraftDto>[];
  Object? startError;
  final startCalls = <ReturnExchangeStartRequest>[];

  ReturnExchangeDraftDto? updateResult;
  final updateResults = <ReturnExchangeDraftDto>[];
  Object? updateError;
  final updateCalls = <ReturnExchangeUpdateRequest>[];

  ReturnExchangeResultDto? cancelResult;
  final cancelResults = <ReturnExchangeResultDto>[];
  Object? cancelError;
  final cancelCalls = <ReturnExchangeMutationRequest>[];

  ReturnExchangeResultDto? confirmResult;
  final confirmResults = <ReturnExchangeResultDto>[];
  Object? confirmError;
  final confirmCalls = <ReturnExchangeConfirmRequest>[];

  ReturnExchangeValuationDto? evaluateResult;
  final evaluateResults = <ReturnExchangeValuationDto>[];
  Object? evaluateError;
  final evaluateCalls = <({String returnExchangeId, int expectedSourceVersion})>[];

  @override
  Future<ReturnExchangePrecheckDto> precheck({
    required String salesOrderId,
    int? expectedSourceVersion,
  }) async {
    precheckCalls.add((
      salesOrderId: salesOrderId,
      expectedSourceVersion: expectedSourceVersion,
    ));
    final e = precheckError;
    if (e != null) throw e;
    if (precheckResults.isNotEmpty) return precheckResults.removeAt(0);
    return precheckResult ??
        ReturnExchangePrecheckDto(
          allowed: true,
          sourceVersion: expectedSourceVersion ?? 7,
          blockers: const [],
        );
  }

  @override
  Future<ReturnableOrderLinesDto> getReturnableLines({
    required String salesOrderId,
  }) async {
    returnableCalls.add(salesOrderId);
    final e = returnableError;
    if (e != null) throw e;
    if (returnableResults.isNotEmpty) return returnableResults.removeAt(0);
    return returnableResult ??
        ReturnableOrderLinesDto(
          salesOrderId: salesOrderId,
          sourceVersion: 7,
          lines: const [
            ReturnableOrderLineDto(
              salesOrderLineId: 'line-1',
              product: ProductSnapshotDto(
                productId: 'product-1',
                sku: 'SKU-1',
                displayName: 'Sản phẩm 1',
              ),
              unit: ProductUnitSnapshotDto(
                productUnitId: 'unit-1',
                unitCode: 'BOX',
                unitName: 'Hộp',
              ),
              soldQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
              returnableQuantity: QuantityDto(quantityMicros: QuantityDto.scale * 2),
              originalUnitPrice: MoneyDto(amountMinor: 50000, currencyCode: 'VND'),
            ),
          ],
        );
  }

  @override
  Future<ReturnExchangePricingPreviewDto> previewPricing({
    required String salesOrderId,
    required List<ReturnExchangePricingLineInput> lines,
  }) async {
    previewCalls.add((salesOrderId: salesOrderId, lines: lines));
    final e = previewError;
    if (e != null) throw e;
    if (previewResults.isNotEmpty) return previewResults.removeAt(0);
    return previewResult ??
        ReturnExchangePricingPreviewDto(
          lines: [
            for (final line in lines)
              ReturnExchangePricedLineDto(
                productUnitId: line.productUnitId,
                unitPrice: const MoneyDto(amountMinor: 1000, currencyCode: 'VND'),
                sourceCode: 'LIST',
              ),
          ],
        );
  }

  @override
  Future<ReturnExchangeDetailDto> getDetail({
    required String returnExchangeId,
  }) async {
    detailCalls.add(returnExchangeId);
    final gate = detailGate;
    if (gate != null) await gate.future;
    final e = detailError;
    if (e != null) throw e;
    if (detailResults.isNotEmpty) return detailResults.removeAt(0);
    return detailResult!;
  }

  @override
  Future<ReturnExchangeDraftDto> start(ReturnExchangeStartRequest request) async {
    startCalls.add(request);
    final e = startError;
    if (e != null) throw e;
    if (startResults.isNotEmpty) return startResults.removeAt(0);
    return startResult ??
        ReturnExchangeDraftDto(
          returnExchangeId: 'draft-re-1',
          salesOrderId: request.salesOrderId,
          version: 1,
          status: ReturnExchangeStatus.draft,
          lines: const [],
        );
  }

  @override
  Future<ReturnExchangeDraftDto> update(ReturnExchangeUpdateRequest request) async {
    updateCalls.add(request);
    final e = updateError;
    if (e != null) throw e;
    if (updateResults.isNotEmpty) return updateResults.removeAt(0);
    return updateResult ??
        ReturnExchangeDraftDto(
          returnExchangeId: request.returnExchangeId,
          salesOrderId: 'order-1',
          version: request.expectedVersion + 1,
          status: ReturnExchangeStatus.draft,
          lines: const [],
        );
  }

  @override
  Future<ReturnExchangeResultDto> cancel(ReturnExchangeMutationRequest request) async {
    cancelCalls.add(request);
    final e = cancelError;
    if (e != null) throw e;
    if (cancelResults.isNotEmpty) return cancelResults.removeAt(0);
    return cancelResult ??
        ReturnExchangeResultDto(
          returnExchangeId: request.returnExchangeId,
          salesOrderId: 'order-1',
          version: (request.expectedVersion ?? 1) + 1,
          status: ReturnExchangeStatus.cancelled,
        );
  }

  @override
  Future<ReturnExchangeResultDto> confirm(ReturnExchangeConfirmRequest request) async {
    confirmCalls.add(request);
    final e = confirmError;
    if (e != null) throw e;
    if (confirmResults.isNotEmpty) return confirmResults.removeAt(0);
    return confirmResult ??
        ReturnExchangeResultDto(
          returnExchangeId: request.returnExchangeId,
          salesOrderId: 'order-1',
          version: request.expectedVersion + 1,
          status: ReturnExchangeStatus.confirmed,
        );
  }

  @override
  Future<ReturnExchangeValuationDto> evaluate({
    required String returnExchangeId,
    required int expectedSourceVersion,
  }) async {
    evaluateCalls.add((
      returnExchangeId: returnExchangeId,
      expectedSourceVersion: expectedSourceVersion,
    ));
    final e = evaluateError;
    if (e != null) throw e;
    if (evaluateResults.isNotEmpty) return evaluateResults.removeAt(0);
    return evaluateResult!;
  }
}
