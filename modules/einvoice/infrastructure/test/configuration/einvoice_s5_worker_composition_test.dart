import 'package:get_it/get_it.dart';
import 'package:supabase/supabase.dart';
import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/infrastructure.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/me_invoice_delivery_provider_adapter.dart';
import 'package:vet45_einvoice_infrastructure/src/adapters/misa/worker_only_invoice_delivery_provider_port.dart';

void main() {
  group('Einvoice S5 worker composition', () {
    test('ERP enableMisaHttp=false resolves worker-only delivery guard', () {
      final container = GetIt.asNewInstance();
      EinvoiceStartup.initializeForTesting(
        supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
        container: container,
        enableMisaHttp: false,
      );

      expect(
        container.get<IInvoiceDeliveryProviderPort>(),
        isA<WorkerOnlyInvoiceDeliveryProviderPort>(),
      );
      expect(
        container.get<IInvoiceDeliveryProviderPort>(),
        isNot(isA<MeInvoiceDeliveryProviderAdapter>()),
      );

      container.reset();
    });

    test(
      'worker enableMisaHttp=true resolves MeInvoiceDeliveryProviderAdapter',
      () {
        final container = GetIt.asNewInstance();
        EinvoiceStartup.initializeForTesting(
          supabase: SupabaseClient('https://dummy.supabase.co', 'dummy-key'),
          container: container,
          enableMisaHttp: true,
        );

        expect(
          container.get<IInvoiceDeliveryProviderPort>(),
          isA<MeInvoiceDeliveryProviderAdapter>(),
        );

        container.reset();
      },
    );
  });
}
