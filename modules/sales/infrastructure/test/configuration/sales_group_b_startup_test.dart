import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';

void main() {
  group('SalesStartup Group B', () {
    test('production data access registers SupabaseSalesOrderDraftGateway', () {
      final container = GetIt.asNewInstance();
      SalesStartup.initializeForTesting(
        container: container,
        supabase: SupabaseClient('https://example.test', 'anon-key'),
      );

      expect(
        container.get<ISalesOrderDraftGateway>(),
        isA<SupabaseSalesOrderDraftGateway>(),
      );
    });

    test('initializeForTesting routes draft save through injected gateway', () async {
      final gateway = _RecordingDraftGateway(
        saveResult: SalesOrderDraftDto(
          draftId: 'draft-recording-1',
          version: 1,
          status: SalesDraftStatus.active,
          storeId: 'store-1',
          savedAt: DateTime.utc(2026, 8, 11),
          savedByActorId: 'actor-1',
          lines: const [],
          total: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
        ),
      );

      final module = SalesStartup.initializeForTesting(
        supabase: SupabaseClient('https://example.test', 'anon-key'),
        salesOrderDraftGateway: gateway,
      );

      final saved = await module.executeCommandAsync<SalesOrderDraftDto>(
        SaveSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: [
            SalesOrderDraftLineInput(
              productId: 'product-1',
              productSku: 'SKU-1',
              productName: 'Thuoc A',
              productUnitId: 'unit-1',
              unitCode: 'BOX',
              unitName: 'Hop',
              quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
              appliedUnitPrice: const MoneyDto(
                amountMinor: 120000,
                currencyCode: 'VND',
              ),
              lineTotal: const MoneyDto(amountMinor: 120000, currencyCode: 'VND'),
            ),
          ],
          idempotencyKey: 'idem-recording-1',
        ),
      );

      expect(gateway.savedCommand, isNotNull);
      expect(gateway.savedCommand!.tenantId, 'tenant-1');
      expect(gateway.savedCommand!.idempotencyKey, 'idem-recording-1');
      expect(saved.draftId, 'draft-recording-1');
    });
  });
}

final class _RecordingDraftGateway implements ISalesOrderDraftGateway {
  _RecordingDraftGateway({required SalesOrderDraftDto saveResult}) : _saveResult = saveResult;

  final SalesOrderDraftDto _saveResult;
  SaveSalesOrderDraftCommand? savedCommand;

  @override
  Future<SalesOrderDraftDto> save(SaveSalesOrderDraftCommand command) async {
    savedCommand = command;
    return _saveResult;
  }

  @override
  Future<SalesOrderDraftDto> update(UpdateSalesOrderDraftCommand command) {
    throw UnimplementedError();
  }

  @override
  Future<SalesOrderDraftDto> cancel(CancelSalesOrderDraftCommand command) {
    throw UnimplementedError();
  }

  @override
  Future<SalesOrderDraftForRestoreDto> getForRestore(
    GetSalesOrderDraftForRestoreQuery query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PagedSalesOrderDraftListDto> list(ListSalesOrderDraftsQuery query) {
    throw UnimplementedError();
  }
}
