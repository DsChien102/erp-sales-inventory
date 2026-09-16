import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_infrastructure/src/domain/issuance/supabase_publish_series_lease_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

void main() {
  group('SupabasePublishSeriesLeaseGateway', () {
    late FakeEinvoiceRpcSupabase supabase;
    late SupabasePublishSeriesLeaseGateway gateway;

    setUp(() {
      supabase = FakeEinvoiceRpcSupabase();
      gateway = SupabasePublishSeriesLeaseGateway(
        rpcClient: _rpcClient(supabase),
      );
    });

    test('acquire maps fencing version and database lease deadline', () async {
      supabase.registerHandler('acquire_publish_series_lease', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_attempt_id': 'attempt-1',
          'p_owner_token': 'command-1',
          'p_lease_seconds': 300,
        });
        return [
          {
            'acquired': true,
            'provider_connection_id': 'connection-1',
            'invoice_series': '1C26TYY',
            'lease_version': 7,
            'leased_until': '2026-09-16T10:05:00Z',
            'retry_after_seconds': 0,
          },
        ];
      });

      final outcome = await gateway.tryAcquire(
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        ownerToken: 'command-1',
      );

      expect(outcome, isA<PublishSeriesLeaseAcquired>());
      final acquired = outcome as PublishSeriesLeaseAcquired;
      expect(acquired.leaseVersion, 7);
      expect(acquired.leasedUntil, DateTime.utc(2026, 9, 16, 10, 5));
    });

    test('busy uses retry delay calculated by database', () async {
      supabase.registerHandler('acquire_publish_series_lease', (_) async {
        return [
          {
            'acquired': false,
            'provider_connection_id': 'connection-1',
            'invoice_series': '1C26TYY',
            'lease_version': 7,
            'leased_until': '2026-09-16T10:05:00Z',
            'retry_after_seconds': 19,
          },
        ];
      });

      final outcome = await gateway.tryAcquire(
        tenantId: 'tenant-1',
        attemptId: 'attempt-1',
        ownerToken: 'command-2',
      );

      expect(outcome, isA<PublishSeriesLeaseBusy>());
      expect(
        (outcome as PublishSeriesLeaseBusy).retryAfter,
        const Duration(seconds: 19),
      );
    });

    test('renew and release carry the fencing version', () async {
      supabase.registerHandler('renew_publish_series_lease', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_provider_connection_id': 'connection-1',
          'p_invoice_series': '1C26TYY',
          'p_owner_token': 'command-1',
          'p_lease_version': 7,
          'p_lease_seconds': 300,
        });
        return [
          {'renewed': true, 'leased_until': '2026-09-16T10:10:00Z'},
        ];
      });
      supabase.registerHandler('release_publish_series_lease', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_provider_connection_id': 'connection-1',
          'p_invoice_series': '1C26TYY',
          'p_owner_token': 'command-1',
          'p_lease_version': 7,
        });
        return null;
      });

      final renewal = await gateway.renew(
        tenantId: 'tenant-1',
        providerConnectionId: 'connection-1',
        invoiceSeries: '1C26TYY',
        ownerToken: 'command-1',
        leaseVersion: 7,
      );
      expect(renewal, isA<PublishSeriesLeaseRenewed>());

      await gateway.release(
        tenantId: 'tenant-1',
        providerConnectionId: 'connection-1',
        invoiceSeries: '1C26TYY',
        ownerToken: 'command-1',
        leaseVersion: 7,
      );
    });

    test('stale renew maps to lost', () async {
      supabase.registerHandler('renew_publish_series_lease', (_) async {
        return [
          {'renewed': false, 'leased_until': null},
        ];
      });

      final renewal = await gateway.renew(
        tenantId: 'tenant-1',
        providerConnectionId: 'connection-1',
        invoiceSeries: '1C26TYY',
        ownerToken: 'command-1',
        leaseVersion: 7,
      );

      expect(renewal, isA<PublishSeriesLeaseLost>());
    });
  });
}
