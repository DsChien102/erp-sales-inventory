import 'package:test/test.dart';
import 'package:vet45_adapters/vet45_adapters.dart';
import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_provider_connection_command_gateway.dart';
import 'package:vet45_einvoice_infrastructure/src/data_access/supabase_provider_connection_read_gateway.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../support/fake_einvoice_rpc_supabase.dart';

SupabaseSchemaRpcClient _rpcClient(FakeEinvoiceRpcSupabase supabase) {
  return SupabaseSchemaRpcClient(
    supabase: supabase,
    schema: 'einvoice',
    mapError: (error, [stackTrace]) => RpcException(error.toString()),
  );
}

void main() {
  test(
    'connect sends tenant, authenticated actor, and credential contract',
    () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('connect_provider', (params) async {
          expect(params, {
            'p_tenant_id': 'tenant-1',
            'p_actor_id': 'actor-1',
            'p_username': 'sandbox-user@example.vn',
            'p_password': 'secret',
            'p_expected_connection_version': 4,
          });
          return [
            {'connection_id': 'connection-1', 'status': 'CHECK_REQUIRED'},
          ];
        });
      final gateway = SupabaseProviderConnectionCommandGateway(
        rpcClient: _rpcClient(supabase),
      );

      final result = await gateway.connect(
        ConnectProviderCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          username: '  sandbox-user@example.vn  ',
          password: 'secret',
          expectedConnectionVersion: 4,
        ),
      );

      expect(supabase.calls.single.functionName, 'connect_provider');
      expect(result.connectionId, 'connection-1');
      expect(result.status, ProviderConnectionStatus.checkRequired);
    },
  );

  test(
    'connection screen sends tenant and actor and maps masked account',
    () async {
      final supabase = FakeEinvoiceRpcSupabase()
        ..registerHandler('get_provider_connection_screen', (params) async {
          expect(params, {'p_tenant_id': 'tenant-1', 'p_actor_id': 'actor-1'});
          return [
            {
              'legal_profile': {
                'legal_name': 'Công ty Sandbox',
                'tax_code': '0101234567',
                'address': 'Hà Nội',
              },
              'connection': {
                'connection_id': 'connection-1',
                'status': 'CONNECTED',
                'connection_version': 7,
                'last_checked_at': '2026-08-30T01:00:00.000Z',
                'masked_account': 'sa***@example.vn',
              },
            },
          ];
        });
      final gateway = SupabaseProviderConnectionReadGateway(
        rpcClient: _rpcClient(supabase),
      );

      final screen = await gateway.getConnectionScreen(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
      );

      expect(
        supabase.calls.single.functionName,
        'get_provider_connection_screen',
      );
      expect(screen.legalProfile.taxCode, '0101234567');
      expect(screen.connection.status, ProviderConnectionStatus.connected);
      expect(screen.connection.maskedAccount, 'sa***@example.vn');
      expect(screen.connection.connectionVersion, 7);
    },
  );

  test('worker result sends the queued compare-and-set version', () async {
    final supabase = FakeEinvoiceRpcSupabase()
      ..registerHandler('record_connection_verified', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_connection_id': 'connection-1',
          'p_expected_connection_version': 9,
          'p_status': 'CONNECTED',
          'p_correlation_id': 'sync-1',
        });
        return [
          {'connection_id': 'connection-1', 'status': 'CONNECTED'},
        ];
      });
    final gateway = SupabaseProviderConnectionCommandGateway(
      rpcClient: _rpcClient(supabase),
    );

    await gateway.recordConnectionVerified(
      RecordConnectionVerifiedCommand(
        tenantId: 'tenant-1',
        connectionId: 'connection-1',
        expectedConnectionVersion: 9,
        status: ProviderConnectionStatus.connected,
        correlationId: 'sync-1',
      ),
    );

    expect(supabase.calls.single.functionName, 'record_connection_verified');
  });

  test('reconnect sends optimistic connection version', () async {
    final supabase = FakeEinvoiceRpcSupabase()
      ..registerHandler('reconnect_provider', (params) async {
        expect(params, {
          'p_tenant_id': 'tenant-1',
          'p_actor_id': 'actor-1',
          'p_connection_id': 'connection-1',
          'p_username': 'sandbox-user@example.vn',
          'p_password': 'new-secret',
          'p_expected_connection_version': 11,
        });
        return [
          {'connection_id': 'connection-1', 'status': 'CHECK_REQUIRED'},
        ];
      });
    final gateway = SupabaseProviderConnectionCommandGateway(
      rpcClient: _rpcClient(supabase),
    );

    final result = await gateway.reconnect(
      ReconnectProviderCommand(
        tenantId: 'tenant-1',
        actorId: 'actor-1',
        connectionId: 'connection-1',
        username: 'sandbox-user@example.vn',
        password: 'new-secret',
        expectedConnectionVersion: 11,
      ),
    );

    expect(result.status, ProviderConnectionStatus.checkRequired);
  });
}
