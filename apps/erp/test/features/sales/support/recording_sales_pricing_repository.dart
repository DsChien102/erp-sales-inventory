import 'dart:async';

import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/pricing/data/models.dart';
import 'package:erp/features/pricing/data/sales_pricing_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

class _UnusedClient extends Fake implements SupabaseClient {}

final _unusedRpc = SupabaseRpc(_UnusedClient());

final class SalesPricingPreviewCall {
  const SalesPricingPreviewCall({
    required this.storeId,
    required this.customerId,
    required this.currencyCode,
    required this.contextVersion,
    required this.effectiveAt,
    required this.lines,
  });

  final String storeId;
  final String? customerId;
  final String currencyCode;
  final int contextVersion;
  final DateTime effectiveAt;
  final List<SalesPricingLineInput> lines;
}

final class SalesManualPriceEvaluateCall {
  const SalesManualPriceEvaluateCall({
    required this.storeId,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    required this.currencyCode,
    required this.contextVersion,
    required this.manualUnitPriceMinor,
    required this.manualDiscountMinor,
    required this.manualDiscountBasisPoints,
    required this.acknowledgeBelowFloor,
  });

  final String storeId;
  final String? customerId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final String currencyCode;
  final int contextVersion;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;
  final bool acknowledgeBelowFloor;
}

typedef SalesPricingPreviewResponder =
    FutureOr<SalesWorkingStatePricingPreviewDto> Function({
      required String storeId,
      String? customerId,
      required String currencyCode,
      required int contextVersion,
      required DateTime effectiveAt,
      required List<SalesPricingLineInput> lines,
    });

typedef SalesManualPriceEvaluateResponder =
    FutureOr<SalesManualPriceEvaluationDto> Function({
      required String storeId,
      String? customerId,
      required String productId,
      required String productUnitId,
      required int quantityMicros,
      required String currencyCode,
      required int contextVersion,
      int? manualUnitPriceMinor,
      int? manualDiscountMinor,
      int? manualDiscountBasisPoints,
      required bool acknowledgeBelowFloor,
    });

class RecordingSalesPricingRepository extends SalesPricingRepository {
  RecordingSalesPricingRepository({
    this.previewResponder,
    this.evaluateResponder,
  }) : super(rpc: _unusedRpc, tenantId: () async => 'tenant-test');

  SalesPricingPreviewResponder? previewResponder;
  SalesManualPriceEvaluateResponder? evaluateResponder;

  final List<SalesPricingPreviewCall> previewCalls = [];
  final List<SalesManualPriceEvaluateCall> evaluateCalls = [];

  @override
  Future<SalesWorkingStatePricingPreviewDto> preview({
    required String storeId,
    String? customerId,
    required String currencyCode,
    required int contextVersion,
    required DateTime effectiveAt,
    required List<SalesPricingLineInput> lines,
  }) async {
    previewCalls.add(
      SalesPricingPreviewCall(
        storeId: storeId,
        customerId: customerId,
        currencyCode: currencyCode,
        contextVersion: contextVersion,
        effectiveAt: effectiveAt,
        lines: lines,
      ),
    );
    final responder = previewResponder;
    if (responder == null) {
      throw StateError('Pricing preview not configured');
    }
    return await responder(
      storeId: storeId,
      customerId: customerId,
      currencyCode: currencyCode,
      contextVersion: contextVersion,
      effectiveAt: effectiveAt,
      lines: lines,
    );
  }

  @override
  Future<SalesManualPriceEvaluationDto> evaluateManualPrice({
    required String storeId,
    String? customerId,
    required String productId,
    required String productUnitId,
    required int quantityMicros,
    required String currencyCode,
    required int contextVersion,
    int? manualUnitPriceMinor,
    int? manualDiscountMinor,
    int? manualDiscountBasisPoints,
    required bool acknowledgeBelowFloor,
  }) async {
    evaluateCalls.add(
      SalesManualPriceEvaluateCall(
        storeId: storeId,
        customerId: customerId,
        productId: productId,
        productUnitId: productUnitId,
        quantityMicros: quantityMicros,
        currencyCode: currencyCode,
        contextVersion: contextVersion,
        manualUnitPriceMinor: manualUnitPriceMinor,
        manualDiscountMinor: manualDiscountMinor,
        manualDiscountBasisPoints: manualDiscountBasisPoints,
        acknowledgeBelowFloor: acknowledgeBelowFloor,
      ),
    );
    final responder = evaluateResponder;
    if (responder == null) {
      throw StateError('Manual price evaluation not configured');
    }
    return await responder(
      storeId: storeId,
      customerId: customerId,
      productId: productId,
      productUnitId: productUnitId,
      quantityMicros: quantityMicros,
      currencyCode: currencyCode,
      contextVersion: contextVersion,
      manualUnitPriceMinor: manualUnitPriceMinor,
      manualDiscountMinor: manualDiscountMinor,
      manualDiscountBasisPoints: manualDiscountBasisPoints,
      acknowledgeBelowFloor: acknowledgeBelowFloor,
    );
  }
}

