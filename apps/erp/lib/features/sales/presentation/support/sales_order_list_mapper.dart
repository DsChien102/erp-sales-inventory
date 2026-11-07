import 'package:vet45_design_system/design_system.dart';
import 'package:erp/features/sales/data/models.dart';

import '../models/sales_order/sales_order_list_filters.dart';
import '../models/sales_order/sales_order_list_item_vm.dart';
import '../models/sales_order/sales_order_saved_search_preset.dart';

final class SalesOrderListMapper {
  const SalesOrderListMapper._();

  static SalesOrderListItemVm toVm(SalesOrderListItemDto dto) {
    return SalesOrderListItemVm(
      salesOrderId: dto.salesOrderId,
      orderNumber: dto.orderNumber,
      sourceVersion: dto.sourceVersion,
      completedAt: dto.committedAt,
      customerLabel: dto.customer?.displayName ?? 'Khách Lẻ',
      customerPhone: dto.customer?.phoneNumber,
      storeLabel: dto.store.displayName,
      total: dto.total,
      lifecycleStatus: dto.lifecycleStatus,
      lockStatus: dto.lockStatus,
      settlementStatus: dto.settlementStatus,
      hasReturnExchange: dto.returnStatus != SalesOrderReturnProjectionStatus.none,
      eInvoiceIssued: dto.eInvoiceStatus == IntegrationDeliveryStatus.delivered,
    );
  }

  static SalesOrderListFilterInput toFilterInput({
    required SalesOrderSavedSearchPreset preset,
    required SalesOrderListTimeFilter timeFilter,
    required SalesOrderListLifecycleFilter lifecycleFilter,
    required SalesOrderListSettlementFilter settlementFilter,
    required SalesOrderListPostSaleFilter postSaleFilter,
    required SalesOrderListEInvoiceFilter eInvoiceFilter,
    required DateTime now,
    String? storeId,
  }) {
    final range = _timeRangeFor(timeFilter, now);
    return SalesOrderListFilterInput(
      completedFrom: range?.from,
      completedTo: range?.to,
      storeId: storeId,
      lifecycleStatus: _lifecycleFor(lifecycleFilter),
      settlementStatus: _settlementFor(preset, settlementFilter),
      hasOutstandingReceivable: _isOutstandingReceivableScope(preset, settlementFilter)
          ? true
          : null,
      hasReturnExchange: postSaleFilter == SalesOrderListPostSaleFilter.hasReturnExchange
          ? true
          : null,
      eInvoiceStatus: _eInvoiceFor(preset, eInvoiceFilter),
    );
  }

  static bool isOutstandingReceivableStatus(SalesSettlementStatus status) {
    return status == SalesSettlementStatus.unpaid || status == SalesSettlementStatus.partiallyPaid;
  }

  static Map<SalesOrderSavedSearchPreset, int> presetCountsFrom(
    SalesOrderListFacetsDto? facets, {
    required int totalAvailable,
  }) {
    if (facets == null) {
      return {
        SalesOrderSavedSearchPreset.all: totalAvailable,
        SalesOrderSavedSearchPreset.outstandingReceivable: 0,
        SalesOrderSavedSearchPreset.eInvoicePending: 0,
      };
    }
    return {
      SalesOrderSavedSearchPreset.all: facets.all,
      SalesOrderSavedSearchPreset.outstandingReceivable: facets.outstandingReceivable,
      SalesOrderSavedSearchPreset.eInvoicePending: facets.eInvoicePending,
    };
  }

  static DateTimeRange? _timeRangeFor(SalesOrderListTimeFilter filter, DateTime now) {
    return switch (filter) {
      SalesOrderListTimeFilter.all => null,
      SalesOrderListTimeFilter.today => () {
        final range = VDateTime.businessDayRangeUtc(now: now, days: 1);
        return DateTimeRange(from: range.fromUtc, to: range.toUtc);
      }(),
      SalesOrderListTimeFilter.last7Days => () {
        final range = VDateTime.businessDayRangeUtc(now: now, days: 7);
        return DateTimeRange(from: range.fromUtc, to: range.toUtc);
      }(),
      SalesOrderListTimeFilter.last30Days => () {
        final range = VDateTime.businessDayRangeUtc(now: now, days: 30);
        return DateTimeRange(from: range.fromUtc, to: range.toUtc);
      }(),
    };
  }

  static SalesOrderLifecycleStatus? _lifecycleFor(SalesOrderListLifecycleFilter filter) {
    return switch (filter) {
      SalesOrderListLifecycleFilter.all => null,
      SalesOrderListLifecycleFilter.completed => SalesOrderLifecycleStatus.completed,
      SalesOrderListLifecycleFilter.cancelled => SalesOrderLifecycleStatus.cancelled,
    };
  }

  static bool _isOutstandingReceivableScope(
    SalesOrderSavedSearchPreset preset,
    SalesOrderListSettlementFilter filter,
  ) {
    return preset == SalesOrderSavedSearchPreset.outstandingReceivable ||
        filter == SalesOrderListSettlementFilter.outstandingReceivable;
  }

  static SalesSettlementStatus? _settlementFor(
    SalesOrderSavedSearchPreset preset,
    SalesOrderListSettlementFilter filter,
  ) {
    if (preset == SalesOrderSavedSearchPreset.outstandingReceivable) {
      return null;
    }
    return switch (filter) {
      SalesOrderListSettlementFilter.all => null,
      SalesOrderListSettlementFilter.paid => SalesSettlementStatus.paid,
      SalesOrderListSettlementFilter.outstandingReceivable => null,
      SalesOrderListSettlementFilter.unpaid => SalesSettlementStatus.unpaid,
    };
  }

  static IntegrationDeliveryStatus? _eInvoiceFor(
    SalesOrderSavedSearchPreset preset,
    SalesOrderListEInvoiceFilter filter,
  ) {
    if (preset == SalesOrderSavedSearchPreset.eInvoicePending) {
      return IntegrationDeliveryStatus.queued;
    }
    return switch (filter) {
      SalesOrderListEInvoiceFilter.all => null,
      SalesOrderListEInvoiceFilter.pending => IntegrationDeliveryStatus.queued,
      SalesOrderListEInvoiceFilter.issued => IntegrationDeliveryStatus.delivered,
    };
  }
}

final class DateTimeRange {
  const DateTimeRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}
