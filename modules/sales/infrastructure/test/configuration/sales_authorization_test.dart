import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/infrastructure.dart';
import 'package:vet45_shared_application/application.dart';

/// Proves the CQRS bus enforces access: commands via the DefaultCommandPipeline
/// authorization decorator, S04 queries via explicit in-handler checks.
void main() {
  group('SalesStartup authorization', () {
    SupabaseClient supabase() => SupabaseClient('https://example.test', 'anon-key');

    test('draft save command is blocked when permission is denied', () {
      final module = SalesStartup.initializeForTesting(
        supabase: supabase(),
        permissionChecker: _DenyingPermissionChecker(),
      );

      expect(
        () => module.executeCommandAsync<SalesOrderDraftDto>(
          SaveSalesOrderDraftCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            storeId: 'store-1',
            currencyCode: 'VND',
            idempotencyKey: 'save-denied',
            lines: [
              SalesOrderDraftLineInput(
                productId: 'product-1',
                productSku: 'SKU-1',
                productName: 'Product 1',
                productUnitId: 'unit-1',
                unitCode: 'BOX',
                unitName: 'Hop',
                quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
                appliedUnitPrice: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
                lineTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
              ),
            ],
          ),
        ),
        throwsA(isA<_PermissionDenied>()),
      );
    });

    test('draft cancel command is blocked by generated authorization metadata', () {
      final module = SalesStartup.initializeForTesting(
        supabase: supabase(),
        permissionChecker: _DenyingPermissionChecker(),
      );

      expect(
        () => module.executeCommandAsync<SalesOrderDraftDto>(
          CancelSalesOrderDraftCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            draftId: 'draft-1',
            storeId: 'store-1',
            expectedVersion: 1,
            idempotencyKey: 'cancel-draft-denied',
          ),
        ),
        throwsA(isA<_PermissionDenied>()),
      );
    });

    test('S04 pricing preview query is blocked when permission is denied', () {
      final module = SalesStartup.initializeForTesting(
        supabase: supabase(),
        permissionChecker: _DenyingPermissionChecker(),
      );

      expect(
        () => module.executeQueryAsync<PricingPreviewDto>(
          PreviewSalesPricingQuery(
            tenantId: 'tenant-1',
            workingState: SalesOrderWorkingStateDto(
              store: const StoreSnapshotDto(
                storeId: 'store-1',
                storeCode: 'S01',
                displayName: 'Store 1',
              ),
              currencyCode: 'VND',
              lines: const [
                CheckoutLineInput(
                  productId: 'product-1',
                  productUnitId: 'unit-1',
                  quantity: QuantityDto(quantityMicros: QuantityDto.scale),
                  unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
                ),
              ],
            ),
          ),
        ),
        throwsA(isA<_PermissionDenied>()),
      );
    });
  });
}

final class _PermissionDenied implements Exception {
  const _PermissionDenied(this.permissionCode);
  final String permissionCode;
}

final class _DenyingPermissionChecker implements IPermissionChecker {
  @override
  Future<void> require(String permissionCode) async {
    throw _PermissionDenied(permissionCode);
  }
}
