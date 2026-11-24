import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/core/supabase/supabase_rpc.dart';
import 'package:erp/features/einvoice/data/einvoice_configuration_repository.dart';
import 'package:erp/features/einvoice/data/einvoice_errors.dart';
import 'package:erp/features/einvoice/data/einvoice_processor_trigger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'einvoice_parity_expectations.dart';

class _Call {
  _Call(this.schema, this.fn, this.params);
  final String schema;
  final String fn;
  final Map<String, dynamic>? params;
}

class _RecordingRpc implements SupabaseRpc {
  final calls = <_Call>[];
  Object? result;
  Object? error;

  @override
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic>? params}) async {
    calls.add(_Call(schema, fn, params));
    final e = error;
    if (e != null) {
      if (e is PostgrestException) {
        throw AppException.from(e);
      }
      if (e is AppException) throw e;
      throw AppException.from(e);
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> rows(
    String schema,
    String fn, {
    Map<String, dynamic>? params = const {},
  }) async {
    final raw = await call(schema, fn, params: params);
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    }
    if (raw is Map) {
      return [Map<String, dynamic>.from(raw)];
    }
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyFunctions implements FunctionsClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingTrigger extends EInvoiceProcessorTrigger {
  _RecordingTrigger() : super(_DummyFunctions());
  final kicks = <String>[];

  @override
  void kick(String tenantId) {
    kicks.add(tenantId);
  }
}

void main() {
  const tenant = parityTenantId;
  const actor = parityActorId;

  late _RecordingRpc rpc;
  late _RecordingTrigger trigger;
  late EInvoiceConfigurationRepository repository;
  var tenantReadCount = 0;
  var actorReadCount = 0;

  setUp(() {
    rpc = _RecordingRpc();
    trigger = _RecordingTrigger();
    tenantReadCount = 0;
    actorReadCount = 0;
    repository = EInvoiceConfigurationRepository(
      rpc: rpc,
      trigger: trigger,
      tenantId: () async {
        tenantReadCount++;
        return tenant;
      },
      actorId: () async {
        actorReadCount++;
        return actor;
      },
    );
  });

  test('kick_after_write_rpcs: connect and reconnect trigger kick', () async {
    rpc.result = [sampleConnectionResultJson()];

    await repository.connect(username: 'user', password: 'pwd');
    expect(trigger.kicks, [tenant]);

    trigger.kicks.clear();
    await repository.reconnect(connectionId: 'conn-1', username: 'user', password: 'pwd');
    expect(trigger.kicks, [tenant]);
  });

  test('no_kick_on_reads: 8 other methods do not trigger kick', () async {
    rpc.result = [sampleConnectionScreenJson()];
    await repository.getConnectionScreen();

    rpc.result = [sampleConnectionResultJson()];
    await repository.disconnect(connectionId: 'conn-1', confirm: true);

    rpc.result = sampleTemplateListJson();
    await repository.listTemplates();

    rpc.result = [sampleIssuanceProfileJson()];
    await repository.getIssuanceProfile();

    rpc.result = [sampleIssuanceProfileJson()];
    await repository.setDefaultConfiguration(templateId: 'tpl', signingConfigId: 'sc');

    rpc.result = [sampleAutomationPolicyJson()];
    await repository.getAutomationPolicy();

    rpc.result = [sampleAutomationPolicyJson()];
    await repository.updateAutomationPolicy(expectedPolicyVersion: 1, autoIssueEnabled: true);

    rpc.result = [sampleConfigurationReadinessJson()];
    await repository.getConfigurationReadiness();

    expect(trigger.kicks, isEmpty);
  });

  test('no_kick_when_rpc_fails: connect fails with PostgrestException does not kick', () async {
    rpc.error = const PostgrestException(message: 'STATE_CHANGED: connection version mismatch');

    await expectLater(
      () => repository.connect(username: 'user', password: 'pwd'),
      throwsA(
        isA<AppException>()
            .having((e) => e.code, 'code', 'STATE_CHANGED')
            .having((e) => e.serverMessage, 'serverMessage', 'STATE_CHANGED: connection version mismatch'),
      ),
    );
    expect(trigger.kicks, isEmpty);
  });

  test('update_policy_config_not_ready (D7): CONFIG_NOT_READY preserves code', () async {
    rpc.error = const PostgrestException(message: 'CONFIG_NOT_READY: auto issue requires readiness');

    await expectLater(
      () => repository.updateAutomationPolicy(expectedPolicyVersion: 1, autoIssueEnabled: true),
      throwsA(
        isA<AppException>().having((e) => e.code, 'code', 'CONFIG_NOT_READY'),
      ),
    );
  });

  test('reconnect_has_no_rule: reconnect does not run checkConnect rule before RPC', () async {
    rpc.result = [sampleConnectionResultJson()];

    await repository.reconnect(connectionId: 'c', username: ' ', password: '');
    expect(rpc.calls.length, 1);
    expect(rpc.calls.first.fn, 'reconnect_provider');
    expect(rpc.calls.first.params?['p_username'], '');
  });

  test('rule_blocks_before_rpc: validation throws before RPC call', () async {
    await expectLater(
      () => repository.connect(username: '   ', password: 'x'),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.validationError)),
    );
    expect(rpc.calls, isEmpty);

    await expectLater(
      () => repository.updateAutomationPolicy(expectedPolicyVersion: 1),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.validationError)),
    );
    expect(rpc.calls, isEmpty);
  });

  test('empty_rows_is_system_error: getIssuanceProfile with [] throws SYSTEM_ERROR', () async {
    rpc.result = <Map<String, dynamic>>[];

    await expectLater(
      () => repository.getIssuanceProfile(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
    );
  });

  test('templates_empty_list: listTemplates with [] returns empty list without error', () async {
    rpc.result = <Map<String, dynamic>>[];

    final templates = await repository.listTemplates();
    expect(templates, isEmpty);
  });

  test('malformed_json_is_system_error: malformed JSON turns into SYSTEM_ERROR', () async {
    rpc.result = [
      {'policy_version': 'not_an_int'},
    ];

    await expectLater(
      () => repository.getAutomationPolicy(),
      throwsA(isA<AppException>().having((e) => e.code, 'code', EInvoiceErrorCodes.systemError)),
    );
  });

  test('tenant_read_each_call: tenantId and actorId closures called once per invocation', () async {
    rpc.result = [sampleIssuanceProfileJson()];

    await repository.getIssuanceProfile();
    expect(tenantReadCount, 1);
    expect(actorReadCount, 1);

    await repository.getIssuanceProfile();
    expect(tenantReadCount, 2);
    expect(actorReadCount, 2);
  });
}
