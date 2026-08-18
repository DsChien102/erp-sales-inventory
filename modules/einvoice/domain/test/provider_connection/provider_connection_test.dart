import 'package:test/test.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('ProviderConnection', () {
    ProviderConnection connection({
      ProviderConnectionStatus status = ProviderConnectionStatus.disconnected,
    }) {
      return ProviderConnection.reconstitute(
        id: const ProviderConnectionId('conn-1'),
        tenantId: TenantId('tenant-1'),
        providerCode: ProviderCode.misaMeinvoice,
        status: status,
        connectionVersion: 1,
      );
    }

    test('markPendingVerification moves to checkRequired', () {
      final conn = connection();
      conn.markPendingVerification();
      expect(conn.status, ProviderConnectionStatus.checkRequired);
      expect(conn.connectionVersion, 2);
    });

    test('markVerified moves to connected with capabilities', () {
      final conn =
          connection(status: ProviderConnectionStatus.checkRequired);
      final now = DateTime.utc(2026, 1, 1);
      conn.markVerified(
        capabilities: const ProviderCapabilitiesSnapshot(
          supportsEmailDelivery: true,
          templateCount: 3,
        ),
        verifiedAt: now,
      );
      expect(conn.status, ProviderConnectionStatus.connected);
      expect(conn.capabilitiesSnapshot?.templateCount, 3);
      expect(conn.lastVerifiedAt, now);
    });

    test('markReconnectRequired from connected', () {
      final conn = connection(status: ProviderConnectionStatus.connected);
      conn.markReconnectRequired();
      expect(conn.status, ProviderConnectionStatus.reconnectRequired);
    });

    test('disconnect requires confirm', () {
      final conn = connection(status: ProviderConnectionStatus.connected);
      expect(
        () => conn.disconnect(confirm: false),
        throwsA(isA<BusinessRuleValidationException>()),
      );
      conn.disconnect(confirm: true);
      expect(conn.status, ProviderConnectionStatus.disconnected);
    });

    test('assertExpectedVersion rejects stale version', () {
      final conn = connection();
      expect(
        () => conn.assertExpectedVersion(99),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}

