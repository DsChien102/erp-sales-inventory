import 'package:test/test.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/einvoice_rpc_mapper.dart';

void main() {
  test('connection screen maps backend-provided masked account', () {
    final screen = EinvoiceRpcMapper.mapConnectionScreen({
      'legal_profile': {
        'legal_name': 'Công ty An Phú',
        'tax_code': '0101234567',
      },
      'connection': {
        'connection_id': 'connection-1',
        'status': 'CONNECTED',
        'connection_version': 7,
        'masked_account': 'ke***@anphu.vn',
      },
    });

    expect(screen.connection.maskedAccount, 'ke***@anphu.vn');
    expect(screen.connection.connectionVersion, 7);
  });

  test('recordConnectionVerifiedParams persists supports_preview', () {
    final params = EinvoiceRpcMapper.recordConnectionVerifiedParams(
      RecordConnectionVerifiedCommand(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
        expectedConnectionVersion: 3,
        status: ProviderConnectionStatus.connected,
        capabilities: const ProviderCapabilitiesSnapshot(
          supportsEmailDelivery: false,
          supportsPreview: true,
          templateCount: 1,
        ),
      ),
    );

    final caps = params['p_capabilities'] as Map<String, dynamic>;
    expect(caps['supports_preview'], isTrue);
    expect(caps['supports_email_delivery'], isFalse);
  });

  test('issuance readiness maps source blockers', () {
    final input = EinvoiceRpcMapper.issuanceReadinessInputFromRow({
      'order_completed': true,
      'buyer_type': 'retail',
      'buyer_name': 'Bán cho người tiêu dùng',
      'config_warnings': <dynamic>[],
      'source_blockers': <dynamic>['ORDER_FULLY_RETURNED'],
    });
    expect(input.sourceBlockers, ['ORDER_FULLY_RETURNED']);
  });

  test('issuance readiness defaults source blockers to empty', () {
    final input = EinvoiceRpcMapper.issuanceReadinessInputFromRow({
      'order_completed': true,
      'buyer_type': 'retail',
      'buyer_name': 'Bán cho người tiêu dùng',
      'config_warnings': <dynamic>[],
    });
    expect(input.sourceBlockers, isEmpty);
  });
}
