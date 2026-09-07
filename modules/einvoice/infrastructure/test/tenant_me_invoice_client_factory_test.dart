import 'package:test/test.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/tenant_me_invoice_client_factory.dart';
import 'package:vet45_misa/e_invoice.dart';

void main() {
  const original = MeInvoiceConfig(
    baseUrl: MeInvoiceConfig.testBaseUrl,
    appId: 'app-id',
    taxCode: '0100000000',
    username: 'user@example.test',
    password: 'old-password',
  );

  test('reuses a tenant client while its connection config is unchanged', () {
    final factory = TenantMeInvoiceClientFactory();

    final first = factory.getOrCreate(tenantId: 'tenant-1', config: original);
    final second = factory.getOrCreate(tenantId: 'tenant-1', config: original);

    expect(identical(first, second), isTrue);
  });

  test('replaces a cached tenant client when credentials change', () {
    final factory = TenantMeInvoiceClientFactory();
    final first = factory.getOrCreate(tenantId: 'tenant-1', config: original);

    final second = factory.getOrCreate(
      tenantId: 'tenant-1',
      config: const MeInvoiceConfig(
        baseUrl: MeInvoiceConfig.testBaseUrl,
        appId: 'app-id',
        taxCode: '0100000000',
        username: 'user@example.test',
        password: 'new-password',
      ),
    );

    expect(identical(first, second), isFalse);
  });
}
