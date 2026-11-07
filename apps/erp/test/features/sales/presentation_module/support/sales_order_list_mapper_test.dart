import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_list_filters.dart';
import 'package:erp/features/sales/presentation/models/sales_order/sales_order_saved_search_preset.dart';
import 'package:erp/features/sales/presentation/support/sales_order_list_mapper.dart';

void main() {
  group('SalesOrderListMapper', () {
    test('maps dto fields to vm preserving committed/status snapshots', () {
      final dto = SalesOrderListItemDto(
        salesOrderId: 'so-1',
        orderNumber: 'SO-001',
        sourceVersion: 9,
        committedAt: DateTime.utc(2026, 8, 12, 3),
        store: const StoreSnapshotDto(
          storeId: 'store-1',
          storeCode: 'HCM',
          displayName: 'Store HCM',
        ),
        customer: const CustomerSnapshotDto(
          customerId: 'cus-1',
          displayName: 'Khach A',
          phoneNumber: '0909',
        ),
        total: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        lifecycleStatus: SalesOrderLifecycleStatus.cancelled,
        lockStatus: SalesOrderLockStatus.locked,
        settlementStatus: SalesSettlementStatus.unpaid,
        returnStatus: SalesOrderReturnProjectionStatus.partiallyReturned,
        eInvoiceStatus: IntegrationDeliveryStatus.queued,
      );

      final vm = SalesOrderListMapper.toVm(dto);

      expect(vm.salesOrderId, dto.salesOrderId);
      expect(vm.sourceVersion, 9);
      expect(vm.completedAt, dto.committedAt);
      expect(vm.lifecycleStatus, SalesOrderLifecycleStatus.cancelled);
      expect(vm.lockStatus, SalesOrderLockStatus.locked);
      expect(vm.hasReturnExchange, isTrue);
      expect(vm.eInvoiceIssued, isFalse);
    });

    test('maps sheet filters + store context into filter input', () {
      final now = DateTime.utc(2026, 8, 12, 10, 30);
      final filter = SalesOrderListMapper.toFilterInput(
        preset: SalesOrderSavedSearchPreset.eInvoicePending,
        timeFilter: SalesOrderListTimeFilter.last7Days,
        lifecycleFilter: SalesOrderListLifecycleFilter.completed,
        settlementFilter: SalesOrderListSettlementFilter.paid,
        postSaleFilter: SalesOrderListPostSaleFilter.hasReturnExchange,
        eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
        now: now,
        storeId: 'store-1',
      );

      expect(filter.storeId, 'store-1');
      // 7 days ending on 2026-08-12 ICT starts at 2026-08-06 00:00 ICT (2026-08-05 17:00 UTC)
      expect(filter.completedFrom, DateTime.utc(2026, 8, 5, 17, 0));
      // and ends at 2026-08-13 00:00 ICT (2026-08-12 17:00 UTC)
      expect(filter.completedTo, DateTime.utc(2026, 8, 12, 17, 0));
      expect(filter.lifecycleStatus, SalesOrderLifecycleStatus.completed);
      expect(filter.settlementStatus, SalesSettlementStatus.paid);
      expect(filter.hasReturnExchange, isTrue);
      expect(filter.eInvoiceStatus, IntegrationDeliveryStatus.queued);
    });

    test('e-invoice chips map all, pending, and issued onto list filter status', () {
      SalesOrderListFilterInput filterFor(SalesOrderListEInvoiceFilter eInvoiceFilter) {
        return SalesOrderListMapper.toFilterInput(
          preset: SalesOrderSavedSearchPreset.all,
          timeFilter: SalesOrderListTimeFilter.all,
          lifecycleFilter: SalesOrderListLifecycleFilter.all,
          settlementFilter: SalesOrderListSettlementFilter.all,
          postSaleFilter: SalesOrderListPostSaleFilter.all,
          eInvoiceFilter: eInvoiceFilter,
          now: DateTime.utc(2026, 8, 12),
        );
      }

      expect(filterFor(SalesOrderListEInvoiceFilter.all).eInvoiceStatus, isNull);
      expect(
        filterFor(SalesOrderListEInvoiceFilter.pending).eInvoiceStatus,
        IntegrationDeliveryStatus.queued,
      );
      expect(
        filterFor(SalesOrderListEInvoiceFilter.issued).eInvoiceStatus,
        IntegrationDeliveryStatus.delivered,
      );
    });

    test('today filter correctly maps early morning ICT (previous day UTC)', () {
      // 01:00 AM ICT on 2026-08-12 is 18:00 UTC on 2026-08-11
      final earlyMorningUtc = DateTime.utc(2026, 8, 11, 18, 0);
      final filter = SalesOrderListMapper.toFilterInput(
        preset: SalesOrderSavedSearchPreset.all,
        timeFilter: SalesOrderListTimeFilter.today,
        lifecycleFilter: SalesOrderListLifecycleFilter.all,
        settlementFilter: SalesOrderListSettlementFilter.all,
        postSaleFilter: SalesOrderListPostSaleFilter.all,
        eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
        now: earlyMorningUtc,
      );

      // Business day 2026-08-12 starts at 2026-08-11 17:00 UTC and ends at 2026-08-12 17:00 UTC
      expect(filter.completedFrom, DateTime.utc(2026, 8, 11, 17, 0));
      expect(filter.completedTo, DateTime.utc(2026, 8, 12, 17, 0));
    });

    test(
      'outstanding receivable preset sets hasOutstandingReceivable and leaves settlementStatus null',
      () {
        final now = DateTime.utc(2026, 8, 12, 10, 30);
        final filter = SalesOrderListMapper.toFilterInput(
          preset: SalesOrderSavedSearchPreset.outstandingReceivable,
          timeFilter: SalesOrderListTimeFilter.all,
          lifecycleFilter: SalesOrderListLifecycleFilter.all,
          settlementFilter: SalesOrderListSettlementFilter.all,
          postSaleFilter: SalesOrderListPostSaleFilter.all,
          eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
          now: now,
        );

        expect(filter.hasOutstandingReceivable, isTrue);
        expect(filter.settlementStatus, isNull);
        expect(
          SalesOrderListMapper.isOutstandingReceivableStatus(SalesSettlementStatus.unpaid),
          isTrue,
        );
        expect(
          SalesOrderListMapper.isOutstandingReceivableStatus(SalesSettlementStatus.partiallyPaid),
          isTrue,
        );
        expect(
          SalesOrderListMapper.isOutstandingReceivableStatus(SalesSettlementStatus.paid),
          isFalse,
        );
      },
    );

    test(
      'outstanding receivable settlement filter sets hasOutstandingReceivable and leaves settlementStatus null',
      () {
        final now = DateTime.utc(2026, 8, 12, 10, 30);
        final filter = SalesOrderListMapper.toFilterInput(
          preset: SalesOrderSavedSearchPreset.all,
          timeFilter: SalesOrderListTimeFilter.all,
          lifecycleFilter: SalesOrderListLifecycleFilter.all,
          settlementFilter: SalesOrderListSettlementFilter.outstandingReceivable,
          postSaleFilter: SalesOrderListPostSaleFilter.all,
          eInvoiceFilter: SalesOrderListEInvoiceFilter.all,
          now: now,
        );

        expect(filter.hasOutstandingReceivable, isTrue);
        expect(filter.settlementStatus, isNull);
      },
    );
  });
}
