import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/einvoice_rpc_mapper.dart';

void main() {
  group('th08_hardening_capability — mapper persistence', () {
    test(
      'recordConnectionVerifiedParams stores template classification fields',
      () {
        final template = ProviderTemplateRef.create(
          templateId: 'tpl-k',
          name: 'Không mã',
          invoiceSeries: '1K26TYY',
          isSendSummary: true,
          serial: '2',
        );

        final params = EinvoiceRpcMapper.recordConnectionVerifiedParams(
          RecordConnectionVerifiedCommand(
            tenantId: 'tenant-1',
            connectionId: 'connection-1',
            expectedConnectionVersion: 1,
            status: ProviderConnectionStatus.connected,
            capabilities: ProviderCapabilitiesSnapshot(
              supportsEmailDelivery: true,
              templateCount: 1,
              templates: [template],
            ),
          ),
        );

        final caps = params['p_capabilities'] as Map<String, dynamic>;
        final stored =
            (caps['templates'] as List).single as Map<String, dynamic>;
        expect(stored['template_id'], 'tpl-k');
        expect(stored['invoice_series'], '1K26TYY');
        expect(stored['symbol'], '1K26TYY');
        expect(stored['invoice_with_code'], isFalse);
        expect(stored['is_mtt'], isFalse);
        expect(stored['is_send_summary'], isTrue);
      },
    );

    test(
      'fromJson round-trips new fields and legacy symbol-only snapshots',
      () {
        final modern = RecordConnectionVerifiedCommand.fromJson({
          'tenant_id': 'tenant-1',
          'connection_id': 'c1',
          'expected_connection_version': 1,
          'status': 'connected',
          'capabilities': {
            'supports_email_delivery': false,
            'template_count': 1,
            'templates': [
              {
                'template_id': 'tpl-1',
                'name': 'A',
                'invoice_series': '2C26MYY',
                'invoice_with_code': true,
                'is_mtt': true,
                'is_send_summary': false,
                'is_available': true,
              },
            ],
          },
        }, id: 'cmd-1');

        expect(modern.capabilities!.templates.single.isMtt, isTrue);
        expect(modern.capabilities!.templates.single.invoiceWithCode, isTrue);
        expect(modern.capabilities!.templates.single.isSendSummary, isFalse);

        final legacy = RecordConnectionVerifiedCommand.fromJson({
          'tenant_id': 'tenant-1',
          'connection_id': 'c1',
          'expected_connection_version': 1,
          'status': 'connected',
          'capabilities': {
            'supports_email_delivery': false,
            'template_count': 1,
            'templates': [
              {
                'template_id': 'tpl-legacy',
                'name': 'Legacy',
                'serial': '1',
                'symbol': '1C26TYY',
                'is_mtt': false,
                'is_available': true,
              },
            ],
          },
        }, id: 'cmd-2');

        final legacyTpl = legacy.capabilities!.templates.single;
        expect(legacyTpl.invoiceSeries, '1C26TYY');
        expect(legacyTpl.invoiceWithCode, isTrue);
        expect(legacyTpl.isMtt, isFalse);
        expect(legacyTpl.isSendSummary, isFalse);
      },
    );

    test('mapTemplateList reads classification columns', () {
      final rows = EinvoiceRpcMapper.mapTemplateList([
        {
          'template_id': 'tpl-k',
          'name': 'Không mã',
          'serial': '2',
          'symbol': '1K26TYY',
          'invoice_series': '1K26TYY',
          'invoice_with_code': false,
          'is_mtt': false,
          'is_send_summary': true,
        },
      ]);

      expect(rows.single.invoiceWithCode, isFalse);
      expect(rows.single.isMtt, isFalse);
      expect(rows.single.isSendSummary, isTrue);
      expect(rows.single.invoiceSeries, '1K26TYY');
    });
  });
}
